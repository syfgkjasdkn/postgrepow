use Mix.Config

# not really needed, but phoenix seems to be imported by pow and :json_library causes a warning
config :phoenix, :json_library, Jason

config :postgrepow, ecto_repos: [PostgrePow.Repo]

import_config "#{Mix.env()}.exs"
