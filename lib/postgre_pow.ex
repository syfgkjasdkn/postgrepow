defmodule PostgrePow do
  @moduledoc File.read!("README.md")
  @behaviour Pow.Store.Base

  use GenServer
  import Ecto.Query
  defstruct invalidators: %{}

  @doc false
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl Pow.Store.Base
  def put(config, key, value) when is_binary(key) do
    GenServer.cast(__MODULE__, {:cache, config, key, value})
  end

  @impl Pow.Store.Base
  def delete(config, key) when is_binary(key) do
    GenServer.cast(__MODULE__, {:delete, config, key})
  end

  @impl Pow.Store.Base
  def get(config, key) when is_binary(key) do
    _get(config, key)
  end

  @impl Pow.Store.Base
  def keys(config) do
    _keys(config)
  end

  # used only in tests
  @doc false
  def give_ets_away(to: pid) do
    GenServer.call(__MODULE__, {:give_away_to, pid})
  end

  @impl GenServer
  def init(_config) do
    __MODULE__ = :ets.new(__MODULE__, [:named_table])
    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_call({:db_get, config, key}, _from, %__MODULE__{invalidators: invalidators} = state) do
    case PostgrePow.Repo.get(PostgrePow.SessionStore, key) do
      %PostgrePow.SessionStore{value: value} when not is_nil(value) ->
        # TODO deal with ttl
        _update(config, key, value)
        {:reply, value, %{state | invalidators: update_invalidators(config, invalidators, key)}}

      _not_found ->
        # TODO
        _update(config, key, nil)

        {:reply, :not_found,
         %{state | invalidators: update_invalidators(config, invalidators, key)}}
    end
  end

  def handle_call({:give_away_to, pid}, _from, state) do
    {:reply, :ets.give_away(__MODULE__, pid, []), state}
  end

  @impl GenServer
  def handle_cast({:cache, config, key, value}, %__MODULE__{invalidators: invalidators} = state) do
    _update(config, key, value)
    {:noreply, %{state | invalidators: update_invalidators(config, invalidators, key)}}
  end

  def handle_cast({:delete, config, key}, %__MODULE__{invalidators: invalidators} = state) do
    _delete(config, key)
    {:noreply, %{state | invalidators: clear_invalidator(invalidators, key)}}
  end

  @impl GenServer
  def handle_info({:invalidate, config, key}, %__MODULE__{invalidators: invalidators} = state) do
    _delete(config, key)
    {:noreply, %{state | invalidators: clear_invalidator(invalidators, key)}}
  end

  defp update_invalidators(config, invalidators, key) do
    case Pow.Config.get(config, :ttl) do
      nil ->
        invalidators

      ttl when is_integer(ttl) ->
        invalidators = clear_invalidator(invalidators, key)
        invalidator = Process.send_after(self(), {:invalidate, config, key}, ttl)
        Map.put(invalidators, key, invalidator)
    end
  end

  defp clear_invalidator(invalidators, key) do
    case Map.pop(invalidators, key) do
      {nil, invalidators} ->
        invalidators

      {invalidator, invalidators} when is_reference(invalidator) ->
        Process.cancel_timer(invalidator)
        invalidators
    end
  end

  defp _get(config, key) do
    key = _key(config, key)

    __MODULE__
    |> :ets.lookup(key)
    |> case do
      [{^key, value}] when not is_nil(value) -> value
      [{^key, nil}] -> :not_found
      [] -> GenServer.call(__MODULE__, {:db_get, config, key})
    end
  end

  defp _update(config, key, value) when not is_nil(value) do
    key = _key(config, key)

    PostgrePow.Repo.insert_all(PostgrePow.SessionStore, [%{key: key, value: value}],
      on_conflict: {:replace, [:value]},
      conflict_target: [:key]
    )

    :ets.insert(__MODULE__, {key, value})
  end

  defp _update(config, key, nil = value) do
    :ets.insert(__MODULE__, {_key(config, key), value})
  end

  defp _delete(config, key) do
    key = _key(config, key)

    PostgrePow.SessionStore
    |> where(key: ^key)
    |> PostgrePow.Repo.delete_all()

    :ets.delete(__MODULE__, key)
  end

  # TODO how often is it called?
  # maybe cache keys in an ets table
  defp _keys(config) do
    namespace = _key(config, "")
    namespace_bytes = byte_size(namespace)
    filter = "#{namespace}%"

    PostgrePow.SessionStore
    |> where([s], like(s.key, ^filter))
    |> select([s], s.key)
    |> PostgrePow.Repo.all()
    # TODO maybe use composite key (namespace, key)
    |> Enum.map(fn <<_namespace::size(namespace_bytes)-bytes>> <> key -> key end)
  end

  @doc false
  def _key(config, key) do
    namespace = Pow.Config.get(config, :namespace, "cache")
    "#{namespace}:#{key}"
  end
end
