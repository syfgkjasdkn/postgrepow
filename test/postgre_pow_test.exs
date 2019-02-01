defmodule PostgrePowTest do
  use ExUnit.Case
  doctest PostgrePow

  test "greets the world" do
    assert PostgrePow.hello() == :world
  end
end
