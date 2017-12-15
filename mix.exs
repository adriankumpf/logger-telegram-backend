defmodule TelegramLoggerBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :telegram_logger_backend,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {TelegramLoggerBackend.Application, []}
    ]
  end

  defp deps do
    [
      {:gen_stage, "~> 0.12"},
      {:nadia, "~> 0.4"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
