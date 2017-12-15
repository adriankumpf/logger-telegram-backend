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
      {:httpoison, "~> 0.13"},
      {:poison, "~> 3.1"}
    ]
  end
end
