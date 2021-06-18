defmodule Fermo.Live.DependenciesTest.FakeModule do
  def config() do
    {:ok, %{pages: []}}
  end
end

defmodule Fermo.Live.DependenciesTest do
  use ExUnit.Case, async: true
  import Mox

  alias Fermo.Live.Dependencies
  alias Fermo.Live.DependenciesTest.FakeModule

  setup :verify_on_exit!

  setup do
    stub(Fermo.ConfigMock, :post_config, fn config -> config end)
    stub(Fermo.I18nMock, :load, fn -> {:ok} end)

    :ok
  end

  describe "init/1" do
    test "it loads i18n" do
      expect(Fermo.I18nMock, :load, fn -> {:ok} end)

      Dependencies.init(app_module: FakeModule)
    end
  end
end
