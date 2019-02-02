use Mix.Config

config :postgrepow, PostgrePow.Repo,
  database: "postgrepow_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

if System.get_env("CI") do
  config :logger, level: :warn

  config :postgrepow, PostgrePow.Repo,
    username: System.get_env("DATABASE_POSTGRESQL_USERNAME"),
    password: System.get_env("DATABASE_POSTGRESQL_PASSWORD")
end
