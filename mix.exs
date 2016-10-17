defmodule RemoteIp.Mixfile do
  use Mix.Project

  def project do
    [app: :remote_ip,
     version: "0.1.0",
     elixir: "~> 1.3",
     package: package,
     description: description,
     deps: deps,
     docs: [source_url: "https://github.com/ajvondrak/remote_ip"]]
  end

  def application, do: [applications: []]

  defp description do
    """
    A plug to overwrite the Conn's remote_ip based on headers such as
    X-Forwarded-For.
    """
  end

  defp package do
    %{files: ~w[lib mix.exs README.md LICENSE],
      maintainers: ["Alex Vondrak"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ajvondrak/remote_ip"}}
  end

  defp deps do
    [{:combine, "~> 0.9.2"},
     {:plug, "~> 1.2"},
     {:inet_cidr, "~> 1.0"},
     {:ex_doc, "~> 0.14", only: :dev}]
  end
end
