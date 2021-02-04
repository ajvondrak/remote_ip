defmodule Level.MixProject do
  use Mix.Project

  def project do
    [
      app: :level,
      version: "0.0.0",
      elixir: "~> 1.7",
      deps: [remote_ip: [path: "../../.."]]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end
end
