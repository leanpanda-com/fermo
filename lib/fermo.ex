defmodule Fermo do
  @moduledoc """
  Fermo provides the main entry points for configuring a project
  """

  @build Application.get_env(:fermo, :build, Fermo.Build)
  @pagination Application.get_env(:fermo, :pagination, Fermo.Pagination)

  def start(_start_type, _args \\ []) do
    {:ok, _pid} = Fermo.Assets.start_link()
    {:ok, _pid} = I18n.start_link()
    {:ok, self()}
  end

  @doc false
  defmacro __using__(opts \\ %{}) do
    quote do
      require Fermo

      @before_compile Fermo
      Module.register_attribute __MODULE__, :config, persist: true
      @config unquote(opts)

      import Fermo.Assets
      import I18n
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def initial_config() do
        hd(__MODULE__.__info__(:attributes)[:config])
        |> Fermo.Config.initial()
      end
    end
  end

  def page(config, template, target, params \\ nil) do
    Fermo.Config.add_page(config, template, target, params)
  end

  def paginate(config, template, options \\ %{}, context \\ %{}, fun \\ nil) do
    @pagination.paginate(config, template, options, context, fun)
  end

  def build(config) do
    @build.run(config)
  end
end
