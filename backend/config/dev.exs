use Mix.Config

config :uptime,
  elks_username: System.get_env("ELKS_USER"),
  elks_key: System.get_env("ELKS_KEY"),
  check_interval: 6 * 60 * 1000
