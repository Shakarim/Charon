defmodule Sphynx.MixProject do
  use Mix.Project

  def project do
    [
      app: :sphynx,
      name: "Sphynx",
      version: "0.1.1",
      elixir: "~> 1.12",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/Shakarim/sphynx"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Sphynx.Application, []}
    ]
  end


  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  @spec description() :: String.t
  defp description(),
       do: "Question-answer based queue for a convenient manage step-by-step execution of business logic"

  @spec package() :: List.t
  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Shakarim/sphynx"}
    ]
  end
end
