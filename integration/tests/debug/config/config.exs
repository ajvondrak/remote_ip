use Mix.Config # for compatibility with Elixir >= 1.7 but < 1.9

config :logger, :console, format: "[$level] $message\n"
config :remote_ip, debug: true
