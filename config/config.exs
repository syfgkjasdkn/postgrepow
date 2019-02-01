use Mix.Config

config :postgrepow, ecto_repos: [PostgrePow.Repo]

import_config "#{Mix.env()}.exs"
