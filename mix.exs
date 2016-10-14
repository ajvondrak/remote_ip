defmodule RemoteIp.Mixfile do
  use Mix.Project

  def project do
    [app: :remote_ip,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:plug]]
  end

  defp deps do
    [{:combine, "~> 0.9.2"},
     {:plug, "~> 1.0"},
     {:inet_cidr, "~> 1.0"}]
  end
end
