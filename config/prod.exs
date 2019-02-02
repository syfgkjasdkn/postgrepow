use Mix.Config

config :logger, level: :info

config :postgrepow, PostgrePow.Repo, pool_size: 20
