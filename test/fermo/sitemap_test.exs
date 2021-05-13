defmodule FakeFile.Stream do
  defstruct path: nil

  defimpl Collectable do
    def into(%FakeFile.Stream{path: path}) do
      {
        :ok,
        fn
          :ok, {:cont, text} ->
            send self(), {:fake_file_stream, :into, path, text}
            :ok
          :ok, :done -> :ok
          :ok, :halt -> :ok
        end
      }
    end
  end
end

defmodule Fermo.Template.FakeTemplate do
  def defaults, do: %{}
end

defmodule Fermo.SitemapTest do
  use ExUnit.Case, async: true
  import Mox

  alias Fermo.Sitemap

  setup :verify_on_exit!

  setup do
    stub(FileMock, :stream!, fn path, _ -> %FakeFile.Stream{path: path} end)
    stub(FileMock, :write!, fn _, _ -> :ok end)
    stub(FileMock, :write!, fn _, _, _ -> :ok end)

    stub(Fermo.TemplateMock, :module_for_template, fn _ -> Fermo.Template.FakeTemplate end)

    %{
      base_url: "https://example.com",
      sitemap: %{},
      pages: [
        %{
          target: "/foo/bar/1/index.html",
          template: "fake_template",
          path: "/foo/bar/1"
        }
      ],
      stats: %{}
    }
  end

  test "it writes the xml declaration", config do
    stub(FileMock, :write!, fn _, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" -> :ok end)

    Sitemap.build(config)
  end

  test "it uses page paths as locations", config do
    Sitemap.build(config)

    receive do
      {:fake_file_stream, :into, _path, entry} ->
        assert entry =~ ~r(<loc>https://example.com/foo/bar/1</loc>)
    after
      1_000 -> flunk("Expected :fake_file_stream not received within 1s")
    end
  end

  test "it produces correct ISO8601 timestamps", config do
    Sitemap.build(config)

    receive do
      {:fake_file_stream, :into, _path, entry} ->
        assert entry =~ ~r[<lastmod>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(.\d+)?Z</lastmod>]
    after
      1_000 -> flunk("Expected :fake_file_stream not received within 1s")
    end
  end

  test "without config.base_url, it fails", config do
    config = Map.delete(config, :base_url)

    assert_raise KeyError, ~r(key :base_url not found), fn ->
      Sitemap.build(config)
    end
  end

  test "with sitemap that isn't a Map, it fails", config do
    config = Map.put(config, :sitemap, true)

    assert_raise FunctionClauseError, ~r/no function clause matching in Access.get\/3/, fn ->
      Sitemap.build(config)
    end
  end

  test "without configuration, it returns the config unchanged" do
    new_config = Sitemap.build(%{})

    assert new_config == %{}
  end
end
