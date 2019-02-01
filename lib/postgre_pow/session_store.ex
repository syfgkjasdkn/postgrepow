defmodule PostgrePow.SessionStore do
  use Ecto.Schema

  @primary_key false
  schema "session_store" do
    field(:key, :string, primary_key: true)
    field(:value, PostgrePow.ValueType)
  end
end
