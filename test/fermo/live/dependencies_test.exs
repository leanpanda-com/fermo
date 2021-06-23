defmodule Fermo.Live.DependenciesTest.FakeModule do
  def config() do
    send(self(), {:call, {__MODULE__, :config, []}})

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

    test "it loads the project's config" do
      Dependencies.init(app_module: FakeModule)

      assert_receive {:call, {Fermo.Live.DependenciesTest.FakeModule, :config, []}}
    end
  end

  describe "handle_call: {:reinitialize}" do
    test "it loads the project's config" do
      Dependencies.handle_call({:reinitialize}, nil, %{app_module: FakeModule})

      assert_receive {:call, {Fermo.Live.DependenciesTest.FakeModule, :config, []}}
    end
  end
end
