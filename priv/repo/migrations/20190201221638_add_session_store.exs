defmodule PostgrePow.Repo.Migrations.AddSessionStore do
  use Ecto.Migration

  def change do
    create table(:session_store, primary_key: false) do
      add(:key, :string, primary_key: true)
      add(:value, :binary, null: false)
    end
  end
end
