defmodule Uptime.MixProject do
  use Mix.Project

  def project do
    [
      app: :uptime,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Uptime.Application, []},
      applications: [:httpotion]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 0.6", only: :dev, runtime: false},
      {:httpotion, "~> 3.1.0"},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end
end
