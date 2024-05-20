defmodule Unleash.Client do
  @moduledoc false

  alias Unleash.Config
  alias Unleash.Features

  @callback features(String.t()) :: Req.Response.t()
  @callback register_client() :: Req.Response.t()
  @callback metrics(map()) :: Req.Response.t()

  @unleash_config Application.compile_env(:unleash_fresha, :unleash_req_options, [])
  @appname "UNLEASH-APPNAME"
  @instance_id "UNLEASH-INSTANCEID"
  @if_none_match "If-None-Match"
  @sdk_version "unleash_ex:#{Mix.Project.config()[:version]}"
  @accept {"Accept", "application/json"}
  @content_type {"Content-Type", "application/json"}

  @telemetry_features_prefix [:unleash, :client, :fetch_features]
  @telemetry_register_prefix [:unleash, :client, :register]
  @telemetry_metrics_prefix [:unleash, :client, :push_metrics]

  def features(etag \\ nil) do
    headers = headers(etag)
    url = "#{Config.url()}/client/features"

    start_metadata = telemetry_metadata(%{etag: etag, url: url})

    :telemetry.span(@telemetry_features_prefix, start_metadata, fn ->
      [base_url: url, headers: headers]
      |> Keyword.merge(@unleash_config)
      |> Req.request()
      |> case do
        {:ok, %{body: nil}} ->
          error = :connection_error
          {{nil, error}, Map.put(start_metadata, :error, error)}

        {:ok, response} ->
          {result, metadata} = handle_feature_response(response)
          {result, Map.merge(start_metadata, metadata)}

        {:error, error} ->
          {{nil, error}, Map.put(start_metadata, :error, error)}
      end
    end)
  end

  def register_client,
    do:
      register(%{
        sdkVersion: @sdk_version,
        strategies: Config.strategy_names(),
        started: DateTime.to_iso8601(DateTime.utc_now()),
        interval: Config.metrics_period()
      })

  def register(client) do
    url = "#{Config.url()}/client/register"

    start_metadata =
      client
      |> Map.take([:sdkVersion, :strategies, :interval])
      |> Map.new(fn
        {:sdkVersion, value} -> {:sdk_version, value}
        {key, value} -> {key, value}
      end)
      |> Map.put(:url, url)
      |> telemetry_metadata()

    :telemetry.span(
      @telemetry_register_prefix,
      start_metadata,
      fn ->
        {result, metadata} = send_data(url, client)
        {result, Map.merge(start_metadata, metadata)}
      end
    )
  end

  def metrics(met) do
    url = "#{Config.url()}/client/metrics"

    start_metadata = telemetry_metadata(%{url: url, metrics_payload: met})

    :telemetry.span(@telemetry_metrics_prefix, start_metadata, fn ->
      {result, metadata} = send_data(url, met)

      {result, Map.merge(start_metadata, metadata)}
    end)
  end

  defp handle_feature_response(response) do
    case response do
      %Req.Response{status: 304} ->
        {:cached, %{http_response_status: 304}}

      %Req.Response{status: 200} ->
        pull_out_data(response)

      %Req.Response{status: status} when is_integer(status) ->
        {:cached, %{http_response_status: status}}
    end
  end

  defp pull_out_data(response) do
    features =
      Features.from_map!(response.body)

    etag =
      response
      |> Req.Response.get_header("etag")
      |> Enum.at(0)

    metadata = %{http_response_status: 200, etag: etag}

    {{etag, features}, metadata}
  end

  defp send_data(url, data) do
    [
      url: url,
      method: :post,
      headers: headers(),
      json: tag_data(data)
    ]
    |> Keyword.merge(@unleash_config)
    |> Req.request()
    |> case do
      {:ok, %Req.Response{status: status} = response} when is_integer(status) ->
        {{:ok, response}, %{http_response_status: status}}

      {:ok, %Req.Response{}} ->
        e = :connection_error
        {{:error, e}, %{error: e}}
    end
  end

  defp headers(nil), do: headers()

  defp headers(etag), do: headers() ++ [{@if_none_match, etag}]

  defp headers,
    do:
      Config.custom_headers() ++
        [{@appname, Config.appname()}, {@instance_id, Config.instance_id()}, @accept, @content_type]

  defp tag_data(data) do
    data
    |> Map.put(:appName, Config.appname())
    |> Map.put(:instanceId, Config.instance_id())
  end

  def telemetry_metadata(metadata \\ %{}) do
    Map.merge(
      %{appname: Config.appname(), instance_id: Config.instance_id()},
      metadata
    )
  end
end
