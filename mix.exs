defmodule Argx.MixProject do
  use Mix.Project

  @description "DSLs for checking args"

  @gitee_repo_url "https://gitee.com/lizhaochao/argx"
  @github_repo_url "https://github.com/lizhaochao/Argx"

  @version "1.1.2"

  def project do
    [
      app: :argx,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Test
      test_pattern: "*_test.exs",

      # Hex
      package: package(),
      description: @description,

      # Docs
      name: "Argx",
      docs: [main: "Argx"]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:atomic_map, "~> 0.9.3"},
      {:credo, "~> 1.5.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24.2", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "argx",
      maintainers: ["lizhaochao"],
      licenses: ["MIT"],
      links: %{"Gitee" => @gitee_repo_url, "GitHub" => @github_repo_url}
    ]
  end

  defp aliases, do: [test: ["format", "test"]]
end
