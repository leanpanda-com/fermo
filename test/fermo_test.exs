defmodule FermoTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  describe "page/4" do
    test "it adds the page" do
      config = Fermo.page(%{pages: []}, "template", "output.html", "params")

      page = hd(config.pages)
      assert page == %{params: "params", filename: "output.html", template: "template"}
    end
  end

  describe "paginate/5" do
    test "it adds pagination" do
      config = %{pages: []}

      expect(Fermo.PaginationMock, :paginate, fn _, _, _, _, _ -> config end)

      Fermo.paginate(config, "template", "options", "context", "fun")
    end
  end

  describe "build/1" do
    test "it builds the site" do
      config = %{pages: []}

      expect(Fermo.BuildMock, :run, fn _ -> {:ok, config} end)

      Fermo.build(config)
    end
  end
end
