defmodule RemoteIp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :remote_ip,
      version: "1.0.0",
      elixir: "~> 1.10",
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer(),
      docs: docs(),
      test_coverage: test_coverage()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp description do
    "A plug to rewrite the Plug.Conn's remote_ip based on request headers" <>
      " such as Forwarded, X-Forwarded-For, X-Client-Ip, and X-Real-Ip"
  end

  defp package do
    %{
      files: ~w[lib mix.exs README.md LICENSE],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ajvondrak/remote_ip"}
    }
  end

  defp deps do
    [
      {:combine, "~> 0.10"},
      {:plug, "~> 1.10"},
      {:ex_doc, "~> 0.22.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:ci, :dev], runtime: false},
      {:excoveralls, "~> 0.15", only: [:ci, :test], runtime: false}
    ]
  end

  defp aliases do
    [integrate: "run integration/tests.exs"]
  end

  defp dialyzer do
    [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}]
  end

  defp docs do
    [
      source_url: "https://github.com/ajvondrak/remote_ip",
      main: "RemoteIp",
      extras: ["extras/algorithm.md"]
    ]
  end

  defp test_coverage() do
    [tool: ExCoveralls]
  end
end
