defmodule RemoteIp.Mixfile do
  use Mix.Project

  def project do
    [app: :remote_ip,
     version: "0.2.1",
     elixir: "~> 1.7",
     package: package(),
     description: description(),
     deps: deps(),
     aliases: aliases(),
     dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}],
     docs: [source_url: "https://github.com/ajvondrak/remote_ip"]]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp description do
    "A plug to overwrite the Conn's remote_ip based on headers such as " <>
    "X-Forwarded-For."
  end

  defp package do
    %{files: ~w[lib mix.exs README.md LICENSE],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ajvondrak/remote_ip"}}
  end

  defp deps do
    [{:combine, "~> 0.10"},
     {:plug, "~> 1.10"},
     {:inet_cidr, "~> 1.0"},
     {:dialyxir, "~> 1.0", only: :dev, runtime: false},
     {:ex_doc, "~> 0.22.0", only: :dev, runtime: false}]
  end

  defp aliases do
    [integrate: "run integration/tests.exs"]
  end
end
