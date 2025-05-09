defmodule CredoUnnecessaryReduce.MixProject do
  use Mix.Project

  @source_url "https://github.com/cheerfulstoic/credo_unnecessary_reduce"

  def project do
    [
      app: :credo_unnecessary_reduce,
      version: "0.3.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      description:
        "Credo check to identify cases where `Enum.reduce` can be simplified to other `Enum` functions",
      licenses: ["MIT"],
      package: package(),
      deps: deps()
    ]
  end

  defp package do
    [
      maintainers: ["Brian Underwood"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        Changelog: "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, ">= 1.0.0"},
      {:mix_test_watch, "~> 1.2", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:benchee, "~> 1.0", only: :dev},
      {:benchee_html, "~> 1.0", only: :dev},
      {:benchee_csv, "~> 1.0", only: :dev}
    ]
  end
end
