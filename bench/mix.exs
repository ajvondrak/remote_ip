defmodule Bench.MixProject do
  use Mix.Project

  def project do
    [
      app: :bench,
      version: "0.0.0",
      elixir: "~> 1.12",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.3"},
      {:benchee_html, "~> 1.0"},
      {:inet_cidr, "~> 1.0"},
      {:cidr, "~> 1.0"},
      {:cider, "~> 0.3"},
      {:remote_ip, path: ".."}
    ]
  end
end
