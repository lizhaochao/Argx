defmodule Argx.MixProject do
  use Mix.Project

  def project do
    [
      app: :argx,
      version: "0.1.0",
      elixir: "~> 1.11",
      aliases: aliases(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["format", "test"]
    ]
  end
end
