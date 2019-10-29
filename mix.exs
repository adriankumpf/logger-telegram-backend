defmodule LoggerTelegramBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logger_telegram_backend,
      version: "1.3.0",
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
      {:hackney, "~> 1.15", optional: true},
      {:mint, "~> 1.0", optional: true},
      {:castore, "~> 0.1", optional: true}
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
