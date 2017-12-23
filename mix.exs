defmodule TelegramLoggerBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :telegram_logger_backend,
      version: "0.3.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Docs
      name: "TelegramLoggerBackend",
      description: " A logger backend for posting messages to Telegram.",
      source_url: "https://github.com/adriankumpf/telegram-logger-backend",
      docs: [main: "readme", extras: ["README.md"]]
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
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:exvcr, "~> 0.8", only: :test},
      {:gen_stage, "~> 0.12"},
      {:httpoison, "~> 0.13"},
      {:poison, "~> 3.1"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/adriankumpf/telegram-logger-backend"},
      maintainers: ["Adrian Kumpf"]
    ]
  end
end
