defmodule LoggerTelegramBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logger_telegram_backend,
      version: "1.0.2",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Docs
      name: "LoggerTelegramBackend",
      description: "A Logger backend for Telegram",
      source_url: "https://github.com/adriankumpf/logger-telegram-backend",
      homepage_url: "https://github.com/adriankumpf/logger-telegram-backend",
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {LoggerTelegramBackend.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:exvcr, "~> 0.10", only: :test},
      {:gen_stage, "~> 0.13"},
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/adriankumpf/logger-telegram-backend"},
      maintainers: ["Adrian Kumpf"]
    ]
  end
end
