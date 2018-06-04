use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :uptime_gui, UptimeGuiWeb.Endpoint,
  secret_key_base: "/NlfZ1po5Q/XX+f3rr0iSvYIz5aV3YnAAKZhGv8YVoOXzvxozYGBHKBHsYW2B7S7"

# Configure your database
config :uptime_gui, UptimeGui.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "uptime_gui_prod",
  pool_size: 15
