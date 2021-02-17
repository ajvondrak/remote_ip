defmodule RemoteIp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :remote_ip,
      version: "0.2.1",
      elixir: "~> 1.7",
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
    "A plug to overwrite the Conn's remote_ip based on headers such as " <>
      "X-Forwarded-For."
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
      {:inet_cidr, "~> 1.0"},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test, runtime: false}
    ]
  end

  defp aliases do
    [integrate: "run integration/tests.exs"]
  end

  defp dialyzer do
    [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}]
  end

  defp docs do
    [source_url: "https://github.com/ajvondrak/remote_ip"]
  end

  defp test_coverage() do
    [tool: ExCoveralls]
  end
end
