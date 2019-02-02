use Mix.Config

config :logger, level: :debug

config :postgrepow, PostgrePow.Repo,
  database: "postgrepow_dev",
  pool_size: 10
