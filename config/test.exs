use Mix.Config

config :postgrepow, PostgrePow.Repo,
  database: "postgrepow_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
