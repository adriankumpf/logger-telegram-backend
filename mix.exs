defmodule LoggerTelegramBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logger_telegram_backend,
      version: "1.1.0-beta.1",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "LoggerTelegramBackend",
      description: "A Logger backend for Telegram",
      source_url: "https://github.com/adriankumpf/logger-telegram-backend",
      homepage_url: "https://github.com/adriankumpf/logger-telegram-backend",
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:exvcr, "~> 0.10", only: :test},
      {:httpoison, "~> 1.0"}
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
