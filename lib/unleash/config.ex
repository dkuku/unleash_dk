defmodule Unleash.Config do
  @moduledoc false

  @defaults [
    url: "http://localhost:4242",
    appname: "test",
    instance_id: "test",
    metrics_period: 10 * 60 * 1000,
    features_period: 15 * 1000,
    strategies: Unleash.Strategies,
    custom_http_headers: []
  ]

  def url() do
    application_env()
    |> Keyword.fetch!(:url)
  end

  def appname() do
    application_env()
    |> Keyword.fetch!(:appname)
  end

  def instance_id() do
    application_env()
    |> Keyword.fetch!(:instance_id)
  end

  def metrics_period() do
    application_env()
    |> Keyword.fetch!(:metrics_period)
  end

  def features_period() do
    application_env()
    |> Keyword.fetch!(:features_period)
  end

  def strategies() do
    strategy_module =
      application_env()
      |> Keyword.fetch!(:strategies)

    strategy_module.strategies()
  end

  def strategy_names() do
    strategies()
    |> Enum.map(fn {n, _} -> n end)
  end

  def backup_file() do
    Path.join([backup_dir(), "repo.json"])
  end

  def backup_dir() do
    Path.join([System.tmp_dir!(), appname()])
  end

  def custom_headers() do
    application_env()
    |> Keyword.fetch!(:custom_http_headers)
  end

  defp application_env() do
    __MODULE__
    |> Application.get_application()
    |> Application.get_env(Unleash, [])
    |> Keyword.merge(@defaults)
  end
end
