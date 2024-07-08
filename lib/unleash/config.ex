defmodule Unleash.Config do
  @moduledoc false

  @defaults [
    url: "",
    appname: "",
    instance_id: "",
    metrics_period: 10 * 60 * 1000,
    features_period: 15 * 1000,
    strategies: Unleash.Strategies,
    backup_file: nil,
    custom_http_headers: [],
    disable_client: false,
    disable_metrics: false,
    retries: -1,
    client: Unleash.Client,
    http_client: Req,
    app_env: :test,
    context: []
  ]

  def url do
    Keyword.fetch!(application_env(), :url)
  end

  def default_context do
    Keyword.fetch!(application_env(), :context)
  end

  def test? do
    Keyword.fetch!(application_env(), :app_env) == :test
  end

  def appname do
    Keyword.fetch!(application_env(), :appname)
  end

  def instance_id do
    Keyword.fetch!(application_env(), :instance_id)
  end

  def metrics_period do
    Keyword.fetch!(application_env(), :metrics_period)
  end

  def features_period do
    Keyword.fetch!(application_env(), :features_period)
  end

  def strategies do
    strategy_module =
      Keyword.fetch!(application_env(), :strategies)

    strategy_module.strategies()
  end

  def strategy_names do
    Enum.map(strategies(), fn {n, _} -> n end)
  end

  def backup_file do
    application_env()
    |> Keyword.fetch!(:backup_file)
    |> case do
      nil -> Path.join([System.tmp_dir!(), appname(), "repo.json"])
      f -> f
    end
  end

  def backup_dir do
    Path.dirname(backup_file())
  end

  def custom_headers do
    Keyword.fetch!(application_env(), :custom_http_headers)
  end

  def disable_client do
    Keyword.fetch!(application_env(), :disable_client)
  end

  def disable_metrics do
    Keyword.fetch!(application_env(), :disable_metrics)
  end

  def retries do
    Keyword.fetch!(application_env(), :retries)
  end

  def client do
    Keyword.fetch!(application_env(), :client)
  end

  def http_client do
    Keyword.fetch!(application_env(), :http_client)
  end

  def application_env do
    config =
      __MODULE__
      |> Application.get_application()
      |> Application.get_env(Unleash, [])

    Keyword.merge(@defaults, config)
  end
end
