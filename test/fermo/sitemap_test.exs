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

defmodule FakeFile do
  def write!(pathname, text, options \\ []) do
    send self(), {:fake_file, :write!, pathname, text, options}
  end

  def stream!(path, _modes \\ [], _line_or_bytes \\ :line) do
    %FakeFile.Stream{path: path}
  end
end

defmodule Fermo.Template.FakeTemplate do
  def defaults, do: %{}
end

defmodule Fermo.SitemapTest do
  use ExUnit.Case, async: true

  alias Fermo.Sitemap

  setup do
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
    Sitemap.build(config, FakeFile)

    assert_receive {:fake_file, :write!, _path, ~s(<?xml version="1.0" encoding="UTF-8"?>\n), []}
  end

  test "it uses page paths as locations", config do
    Sitemap.build(config, FakeFile)

    receive do
      {:fake_file_stream, :into, _path, entry} ->
        assert entry =~ ~r(<loc>https://example.com/foo/bar/1</loc>)
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
