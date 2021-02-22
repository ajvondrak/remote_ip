# TODO: `import Config` when our minimum supported Elixir is ~> 1.9
use Mix.Config

config :logger, :console,
  colors: [enabled: false],
  format: "[$level] $message\n"

config :remote_ip, debug: [:options, :ips]
