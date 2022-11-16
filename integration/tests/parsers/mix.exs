defmodule Parsers.MixProject do
  use Mix.Project

  def project do
    [
      app: :parsers,
      version: "0.0.0",
      elixir: "~> 1.10",
      deps: [remote_ip: [path: "../../.."]]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end
end
