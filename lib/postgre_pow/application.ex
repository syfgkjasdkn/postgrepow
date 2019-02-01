defmodule PostgrePow.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [PostgrePow.Repo]
    opts = [strategy: :one_for_one, name: PostgrePow.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
