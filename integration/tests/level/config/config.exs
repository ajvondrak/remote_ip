# TODO: `import Config` when our minimum supported Elixir is ~> 1.9
use Mix.Config

config :logger, :console,
  format: "$metadata[$level]\n",
  colors: [enabled: false],
  metadata: [:mfa]

config :remote_ip, debug: true, level: :info
