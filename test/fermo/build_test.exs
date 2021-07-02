defmodule Fermo.BuildTest.FakeTemplate do
  def defaults(), do: %{}

  def call(_, _), do: "rendered content"
end

defmodule Fermo.BuildTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  setup do
    stub(Fermo.ConfigMock, :post_config, fn config -> config end)
    stub(Fermo.FileMock, :save, fn _, _ -> :ok end)
    stub(Fermo.I18nMock, :optionally_build_path_map, fn config -> config end)
    stub(Fermo.SitemapMock, :build, fn config -> config end)

    :ok
  end

  test "it builds pages" do
    page = %{
      template: "template",
      filename: "filename",
      params: %{
        module: Fermo.BuildTest.FakeTemplate,
        layout: nil
      },
      pathname: "page/path"
    }
    config = %{build_path: "foo", pages: [page]}

    expect(Fermo.FileMock, :save, fn "page/path", "rendered content" -> :ok end)

    Fermo.Build.run(config)
  end
end
