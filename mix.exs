defmodule Unleash.MixProject do
  @moduledoc false
  use Mix.Project

  @original_gitlab_url "https://www.gitlab.com/afontaine/unleash_ex"
  @github_url "https://www.github.com/surgeventures/unleash_fresha"

  def project do
    [
      app: :unleash_fresha,
      version: "VERSION" |> File.read!() |> String.trim(),
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "Unleash",
      description: "An Unleash Feature Flag client for Elixir, forked from [unleash](#{@original_gitlab_url})",
      source_url: @github_url,
      homepage_url: @github_url,
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Unleash, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:inch_ex, "~> 2.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      {:styler, "~> 0.11", only: [:dev, :test], runtime: false},
      {:expublish, "~> 2.7", only: :dev, runtime: false},
      {:junit_formatter, "~> 3.0", only: :test},
      {:stream_data, "~> 0.4", only: [:test, :dev]},
      {:excoveralls, "~> 0.8", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:recase, "~> 0.6"},
      {:murmur, "~> 1.0"},
      {:mojito_fresha, "~> 0.7"},
      {:jason, "~> 1.1"},
      {:telemetry, "~> 1.1"},
      {:plug, "~> 1.8", optional: true},
      {:phoenix_gon, "~> 0.4.0", optional: true}
    ]
  end

  defp aliases do
    [
      test: ["test --no-start"]
    ]
  end

  defp package do
    [
      files: ~w(mix.exs lib LICENSE README.md CHANGELOG.md VERSION),
      licenses: ["MIT"],
      links: %{
        "Original project" => @original_gitlab_url,
        "github" => @github_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      deps: [
        mojito: "https://hexdocs.pm/mojito/",
        murmur: "https://hexdocs.pm/murmur/",
        plug: "https://hexdocs.pm/plug/",
        phoenix_gon: "https://hexdocs.pm/phoenix_gon/"
      ],
      groups_for_modules: [
        Strategies: ~r"Strateg(y|ies)\."
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]

  defp elixirc_paths(_), do: ["lib"]
end
