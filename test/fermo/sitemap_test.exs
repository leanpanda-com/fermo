defmodule Fermo.SitemapTest do
  use ExUnit.Case, async: true

  alias Fermo.Sitemap

  test "without configuration, it returns the config unchanged" do
    new_config = Sitemap.build(%{})

    assert new_config == %{}
  end
end
