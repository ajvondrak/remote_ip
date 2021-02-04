# TODO: `import Config` when our minimum supported Elixir is ~> 1.9
use Mix.Config

config :logger, :console,
  format: "[$level] $message\n",
  colors: [enabled: false]

config :logger, compile_time_purge_matching: [[level_lower_than: :error]]

config :remote_ip, debug: true, level: :info
