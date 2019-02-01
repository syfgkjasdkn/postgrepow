defmodule PostgrePow.ValueType do
  @behaviour Ecto.Type

  @impl true
  def type, do: :binary

  @impl true
  def cast(anything) do
    {:ok, anything}
  end

  @impl true
  def load(bin) when is_binary(bin) do
    {:ok, :erlang.binary_to_term(bin)}
  end

  @impl true
  def dump(anything) do
    {:ok, :erlang.term_to_binary(anything)}
  end
end
