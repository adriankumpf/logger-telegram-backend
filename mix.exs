defmodule LoggerTelegramBackend.Mixfile do
  use Mix.Project

  @name "LoggerTelegramBackend"
  @version "1.3.0"
  @url "https://github.com/adriankumpf/logger-telegram-backend"

  def project do
    [
      app: :logger_telegram_backend,
      version: @version,
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      aliases: [docs: &build_docs/1],
      description: "A Logger backend for Telegram",
      source_url: "https://github.com/adriankumpf/logger-telegram-backend",
      homepage_url: "https://github.com/adriankumpf/logger-telegram-backend",
      docs: [main: "readme", extras: ["README.md"]],
      name: @name
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
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

  defp build_docs(_) do
    Mix.Task.run("compile")

    ex_doc = Path.join(Mix.path_for(:escripts), "ex_doc")

    unless File.exists?(ex_doc) do
      raise "cannot build docs because escript for ex_doc is not installed"
    end

    args = [@name, @version, Mix.Project.compile_path()]
    opts = ~w[--main #{@name} --source-ref v#{@version} --source-url #{@url}]
    System.cmd(ex_doc, args ++ opts)
    Mix.shell().info("Docs built successfully")
  end
end
