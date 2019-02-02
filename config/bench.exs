use Mix.Config

config :postgrepow, PostgrePow.Repo,
  database: "postgrepow_bench",
  pool_size: 20

config :logger, level: :warn
