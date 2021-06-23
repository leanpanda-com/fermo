defmodule Mix.Fermo.CompilerTest do
  use ExUnit.Case, async: true
  import Mox
  import Fermo.Test.Support.DateTimeHelpers

  setup :verify_on_exit!

  describe "run/0" do
    setup context do
      manifest_timestamp = context[:manifest_timestamp] || 0
      helpers_timestamp = context[:helpers_timestamp] || :calendar.universal_time
      template_timestamp = context[:template_timestamp] || :calendar.universal_time

      stub(FileMock, :write!, fn _, _, _ -> :ok end)
      stub(Fermo.CompilersMock, :compilers, fn -> [slim: Fermo.Compilers.SlimMock] end)
      stub(Fermo.CompilersMock, :templates, fn _path -> [{:slim, "foo.html.slim"}] end)
      stub(Fermo.Compilers.SlimMock, :compile, fn _ -> {:ok} end)
      stub(Mix.Fermo.Compiler.ManifestMock, :timestamp, fn -> manifest_timestamp end)
      stub(Mix.Fermo.Compiler.ManifestMock, :write, fn _, _ -> {:ok} end)
      stub(Mix.UtilsMock, :last_modified, fn filename ->
        case filename do
          "foo.html.slim" -> template_timestamp
          "lib/helpers.ex" -> helpers_timestamp
        end
      end)

      :ok
    end

    test "without a manifest, it compiles all files" do
      expect(Fermo.Compilers.SlimMock, :compile, fn _ -> {:ok} end)

      Mix.Fermo.Compiler.run()
    end

    @tag helpers_timestamp: 0
    @tag manifest_timestamp: offset_datetime(:calendar.universal_time, 10)
    test "without helpers, when there is a manifest, it compiles changed files" do
      expect(Fermo.Compilers.SlimMock, :compile, 1, fn "foo.html.slim" -> {:ok} end)

      Mix.Fermo.Compiler.run()
    end

    @tag helpers_timestamp: 0
    @tag manifest_timestamp: offset_datetime(:calendar.universal_time, 10)
    @tag template_timestamp: offset_datetime(:calendar.universal_time, 20)
    test "without helpers, when there is a manifest, it doesn't compile unchanged files" do
      expect(Fermo.Compilers.SlimMock, :compile, 0, fn _ -> {:ok} end)

      Mix.Fermo.Compiler.run()
    end

    @tag helpers_timestamp: :calendar.universal_time
    @tag manifest_timestamp: offset_datetime(:calendar.universal_time, 100)
    @tag template_timestamp: offset_datetime(:calendar.universal_time, 200)
    test "when helpers has changed, it compiles all templates" do
      expect(Fermo.Compilers.SlimMock, :compile, 1, fn "foo.html.slim" -> {:ok} end)

      Mix.Fermo.Compiler.run()
    end

    @tag helpers_timestamp: offset_datetime(:calendar.universal_time, 200)
    @tag manifest_timestamp: offset_datetime(:calendar.universal_time, 100)
    @tag template_timestamp: offset_datetime(:calendar.universal_time, 200)
    test "when helpers has not changed, it compiles all templates" do
      expect(Fermo.Compilers.SlimMock, :compile, 0, fn _ -> {:ok} end)

      Mix.Fermo.Compiler.run()
    end

    test "it writes the manifest" do
      expect(Mix.Fermo.Compiler.ManifestMock, :write, fn _, _ -> {:ok} end)

      Mix.Fermo.Compiler.run()
    end
  end
end
