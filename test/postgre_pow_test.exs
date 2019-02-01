defmodule PostgrePowTest do
  use ExUnit.Case

  # TODO also test when used via pow, that is, setup pow with postgrepow, and invoke Pow.* functions

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PostgrePow.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(PostgrePow.Repo, {:shared, self()})
    {:ok, pid} = PostgrePow.start_link([])
    {:ok, pid: pid}
  end

  # TODO ideally, (property?) test against an oracle (pow's ets adapter)
  # these are just sanity checks that everything is wired correctly

  describe "put" do
    test "updates db", %{pid: pid} do
      key = "1234"
      value = %{some: :value}
      config = []

      full_key = PostgrePow._key(config, key)

      refute PostgrePow.Repo.get(PostgrePow.SessionStore, full_key)

      :ok = PostgrePow.put(config, key, value)

      # waits for cast to complete
      _ = :sys.get_state(pid)

      # db has it
      assert %PostgrePow.SessionStore{key: ^full_key, value: ^value} =
               PostgrePow.Repo.get(PostgrePow.SessionStore, full_key)

      # ets has it
      true = PostgrePow.give_ets_away(to: self())
      assert [{^full_key, ^value}] = :ets.lookup(PostgrePow, full_key)
    end

    test "put and get", %{pid: pid} do
      key = "1234"
      value = %{some: :value}
      config = []

      :ok = PostgrePow.put(config, key, value)

      # waits for cast to complete
      _ = :sys.get_state(pid)

      assert value == PostgrePow.get(config, key)
    end
  end

  describe "delete" do
    test "put, delete, and get", %{pid: pid} do
      key = "1234"
      value = %{some: :value}
      config = []

      :ok = PostgrePow.put(config, key, value)

      # waits for cast to complete
      _ = :sys.get_state(pid)

      assert value == PostgrePow.get(config, key)

      :ok = PostgrePow.delete(config, key)

      # waits for cast to complete
      _ = :sys.get_state(pid)

      assert :not_found == PostgrePow.get(config, key)
    end

    test "deletes from db", %{pid: pid} do
      key = "1234"
      value = %{some: :value}
      config = []

      full_key = PostgrePow._key(config, key)

      :ok = PostgrePow.put(config, key, value)

      # waits for cast to complete
      _ = :sys.get_state(pid)

      assert value == PostgrePow.get(config, key)

      # db has it
      assert %PostgrePow.SessionStore{key: ^full_key, value: ^value} =
               PostgrePow.Repo.get(PostgrePow.SessionStore, full_key)

      :ok = PostgrePow.delete(config, key)

      # waits for cast to complete
      _ = :sys.get_state(pid)

      # db doesn't have it anymore
      refute PostgrePow.Repo.get(PostgrePow.SessionStore, full_key)
    end
  end

  describe "get" do
    test "when ets doesn't have it but db does" do
      key = "1234"
      value = %{some: :value}
      config = []

      full_key = PostgrePow._key(config, key)

      # insert into db
      PostgrePow.Repo.insert_all(PostgrePow.SessionStore, [%{key: full_key, value: value}])

      assert value == PostgrePow.get(config, key)

      # verify it was cached in ets
      true = PostgrePow.give_ets_away(to: self())
      assert [{^full_key, ^value}] = :ets.lookup(PostgrePow, full_key)
    end
  end

  describe "keys" do
    test "put, put, keys", %{pid: pid} do
      key1 = "1234"
      value1 = %{some: :value1}

      key2 = "1235"
      value2 = %{some: :value2}

      config = []

      :ok = PostgrePow.put(config, key1, value1)
      :ok = PostgrePow.put(config, key2, value2)

      # waits for casts to complete
      _ = :sys.get_state(pid)

      assert ["1234", "1235"] == PostgrePow.keys(config)
    end

    test "loads keys (from db) even when ets doesn't have any" do
      key1 = "1234"
      value1 = %{some: :value1}

      key2 = "1235"
      value2 = %{some: :value2}

      config = []

      PostgrePow.Repo.insert_all(
        PostgrePow.SessionStore,
        [
          %{key: PostgrePow._key(config, key1), value: value1},
          %{key: PostgrePow._key(config, key2), value: value2}
        ]
      )

      assert ["1234", "1235"] == PostgrePow.keys(config)
    end
  end
end
