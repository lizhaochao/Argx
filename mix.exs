defmodule Argx.MixProject do
  use Mix.Project

  def project do
    [
      app: :argx,
      version: "0.2.0",
      elixir: "~> 1.11",
      aliases: aliases(),
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_pattern: "*_test.ex*"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    "A DSL for validating function's args"
  end

  defp package do
    [
      name: "argx",
      licenses: ["MIT"],
      links: %{"Gitee" => "https://gitee.com/leechaochao/argx"}
    ]
  end

  defp aliases do
    [
      test: ["format", "test"]
    ]
  end
end
