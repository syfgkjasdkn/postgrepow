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

    test "put and get" do
      key = "1234"
      value = %{some: :value}
      config = []

      :ok = PostgrePow.put(config, key, value)
      assert value == PostgrePow.get(config, key)
    end
  end

  describe "delete" do
    test "put, delete, and get"
    test "deletes from db"
  end

  describe "get" do
    test "when ets doesn't have it but db does"
    test "when ets has it and db has it as well"
    test "when neither ets nor db have it"
    test "when ets has it but db doesn't"
  end

  describe "keys" do
    test "put, put, keys"
    test "loads keys (from db) even when ets doesn't have any"
  end
end
