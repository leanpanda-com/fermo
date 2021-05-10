defmodule Fermo.NewTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  setup context do
    ls_result = Map.get(context, :ls_result, [])

    stub(FileMock, :ls, fn _ -> ls_result end)
    stub(MixMock, :shell, fn -> Mix.ShellMock end)
    stub(MixMock, :raise, fn message -> raise message end)
    stub(Mix.ShellMock, :info, fn _ -> :ok end)
    stub(Mix.GeneratorMock, :create_directory, fn _ -> true end)
    stub(Mix.GeneratorMock, :create_file, fn _, _ -> true end)

    :ok
  end

  test "it create the directory" do
    test_pid = self()

    stub(Mix.GeneratorMock, :create_directory, fn path ->
      send(test_pid, {:create_directory, path})
      true
    end)

    Fermo.New.run(["pizza"])

    assert_receive {:create_directory, "pizza"}
  end

  test "it generates files" do
    test_pid = self()

    stub(Mix.GeneratorMock, :create_file, fn path, content ->
      send(test_pid, {:create_file, path, content})
      true
    end)

    Fermo.New.run(["pizza"])

    assert_receive {:create_file, "pizza/mix.exs", _}
  end

  test "when the parameters are incoreect, it prints out the help" do
    expect(Mix.Tasks.HelpMock, :run, fn _ -> :ok end)

    Fermo.New.run(["--foo"])
  end

  test "when the name is incorrect, it fails" do
    assert_raise RuntimeError, ~r[app name 'foo/bar' is incorrect], fn ->
      Fermo.New.run(["foo/bar"])
    end
  end

  @tag ls_result: ["file.txt"]
  test "when the directory exists and is not empty, it fails" do
    assert_raise RuntimeError, ~r[directory foo is not empty], fn ->
      Fermo.New.run(["foo"])
    end
  end
end
