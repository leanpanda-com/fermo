defmodule Mix.Fermo.CompilerTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  describe "run/0" do
    setup context do
      manifest_timestamp = Map.get(context, :manifest_timestamp, 0)

      stub(Fermo.CompilerMock, :compile, fn _ -> {:ok} end)
      stub(Mix.Fermo.Compiler.ManifestMock, :timestamp, fn -> manifest_timestamp end)
      stub(Mix.Fermo.Compiler.ManifestMock, :write, fn _, _ -> {:ok} end)
      stub(Mix.UtilsMock, :extract_files, fn _, _ -> ["foo"] end)
      stub(Mix.UtilsMock, :last_modified, fn "foo" -> :calendar.universal_time end)

      :ok
    end

    test "it compiles files" do
      expect(Fermo.CompilerMock, :compile, fn _ -> {:ok} end)

      Mix.Fermo.Compiler.run()
    end

    @tag manifest_timestamp: :calendar.universal_time
    test "it when the manifest has a timestamp, it compiles changed files" do
      expect(Fermo.CompilerMock, :compile, 0, fn _ -> {:ok} end)

      Mix.Fermo.Compiler.run()
    end

    test "it writes the manifest" do
      expect(Mix.Fermo.Compiler.ManifestMock, :write, fn _, _ -> {:ok} end)

      Mix.Fermo.Compiler.run()
    end
  end
end
