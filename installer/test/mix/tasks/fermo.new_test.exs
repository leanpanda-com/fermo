defmodule Mix.Tasks.Fermo.NewTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  test "it runs the generator" do
    expect(Fermo.NewMock, :run, fn ["args"] -> {:ok} end)

    Mix.Tasks.Fermo.New.run(["args"])
  end
end
