defmodule LoggerTelegramBackend.Mixfile do
  use Mix.Project

  @version "3.0.0"
  @source_url "https://github.com/adriankumpf/logger-telegram-backend"

  def project do
    [
      app: :logger_telegram_backend,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "A Logger backend for Telegram",
      source_url: @source_url,
      docs: [
        extras: ["README.md", "CHANGELOG.md"],
        source_ref: "#{@version}",
        source_url: @source_url,
        main: "readme",
        skip_undefined_reference_warnings_on: ["CHANGELOG.md", "README.md"]
      ],
      xref: [exclude: [Finch]]
    ]
  end

  def application do
    [
      mod: {LoggerTelegramBackend.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      if(System.version() >= "1.15.0", do: {:logger_backends, "~> 1.0"}),
      {:finch, "~> 0.16", optional: true},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:exvcr, "~> 0.10", only: :test}
    ]
    |> Enum.reject(&is_nil/1)
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
