import Config

config :logger, :console,
  format: "[$level] $message\n",
  colors: [enabled: false]

config :logger, compile_time_purge_matching: [[level_lower_than: :info]]

config :remote_ip, debug: true
