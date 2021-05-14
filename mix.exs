defmodule Argx.MixProject do
  use Mix.Project

  def project do
    [
      app: :argx,
      version: "1.1.0",
      elixir: "~> 1.11",
      aliases: aliases(),
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_pattern: "*_test.exs",

      # Docs
      name: "Argx",
      docs: [
        main: "Argx"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    "DSLs for checking args"
  end

  defp package do
    [
      name: "argx",
      licenses: ["MIT"],
      links: %{
        "Gitee" => "https://gitee.com/lizhaochao/argx",
        "GitHub" => "https://github.com/lizhaochao/Argx"
      }
    ]
  end

  defp aliases do
    [
      test: ["format", "test"]
    ]
  end
end
