import Config

config :cleaner, Cleaner.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cleaner_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
