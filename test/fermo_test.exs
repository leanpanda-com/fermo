defmodule FermoTest do
  use ExUnit.Case
  doctest Fermo

  test "greets the world" do
    assert Fermo.hello() == :world
  end
end
