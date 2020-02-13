defmodule RemoteIp.Mixfile do
  use Mix.Project

  def project do
    [app: :remote_ip,
     version: "0.2.1",
     elixir: "~> 1.5",
     package: package(),
     description: description(),
     deps: deps(),
     docs: [source_url: "https://github.com/ajvondrak/remote_ip"]]
  end

  def application do
    [applications: [:plug, :combine, :inet_cidr]]
  end

  defp description do
    "A plug to overwrite the Conn's remote_ip based on headers such as " <>
    "X-Forwarded-For."
  end

  defp package do
    %{files: ~w[lib mix.exs README.md LICENSE],
      maintainers: ["Alex Vondrak"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ajvondrak/remote_ip"}}
  end

  defp deps do
    [{:combine, "~> 0.10"},
     {:plug, "~> 1.5"},
     {:inet_cidr, "~> 1.0"},
     {:ex_doc, "~> 0.21", only: :dev}]
  end
end
