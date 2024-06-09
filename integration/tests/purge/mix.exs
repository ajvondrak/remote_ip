defmodule Purge.MixProject do
  use Mix.Project

  def project do
    [
      app: :purge,
      version: "0.0.0",
      elixir: "~> 1.12",
      deps: [remote_ip: [path: "../../.."]]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end
end
