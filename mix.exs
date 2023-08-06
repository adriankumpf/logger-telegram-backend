defmodule LoggerTelegramBackend.Mixfile do
  use Mix.Project

  @version "3.0.0-dev"
  @source_url "https://github.com/adriankumpf/logger-telegram-backend"

  def project do
    [
      app: :logger_telegram_backend,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "A Logger backend for Telegram",
      source_url: "https://github.com/adriankumpf/logger-telegram-backend",
      homepage_url: "https://github.com/adriankumpf/logger-telegram-backend",
      docs: [
        extras: ["README.md", "CHANGELOG.md"],
        source_ref: "#{@version}",
        source_url: @source_url,
        main: "readme",
        skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:exvcr, "~> 0.10", only: :test},
      {:tesla, "~> 1.4"},
      {:logger_backends, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:hackney, "~> 1.15", optional: true}
    ]
  end

  defp package do
    [
      files: ["lib", "LICENSE", "mix.exs", "README.md", "CHANGELOG.md"],
      maintainers: ["Adrian Kumpf"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end
end
