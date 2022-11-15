import Config

config :logger, :console,
  colors: [enabled: false],
  format: "[$level] $message\n"

config :remote_ip, debug: [:options, :ips]
