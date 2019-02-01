defmodule PostgrePow.Repo do
  use Ecto.Repo,
    otp_app: :postgrepow,
    adapter: Ecto.Adapters.Postgres
end
