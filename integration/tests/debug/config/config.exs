use Mix.Config # for compatibility with Elixir >= 1.7 but < 1.9

config :logger, :console,
  colors: [enabled: false],
  format: "[$level] $message\n"

config :remote_ip, debug: true
