defmodule Fermo do
  require EEx
  require Slime
  import Mix.Fermo.Paths, only: [source_path: 0]

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

  def page(config, template, target, params \\ nil, options \\ nil) do
    Fermo.Config.add_page(config, template, target, params, options)
  end

  def paginate(config, template, options \\ %{}, context \\ %{}, fun \\ nil) do
    Fermo.Pagination.paginate(config, template, options, context, fun)
  end

  def build(config) do
    config = put_in(config, [:stats, :build_started], Time.utc_now)

    {:ok} = Fermo.Assets.build()
    {:ok} = Fermo.I18n.load()

    build_path = get_in(config, [:build_path])
    File.mkdir(build_path)

    config =
      config
      |> Fermo.Config.post_config()
      |> copy_statics()
      |> Fermo.Sitemap.build()
      |> Fermo.Build.run()

    {:ok, config}
  end

  defp copy_statics(config) do
    statics = config[:statics]
    build_path = get_in(config, [:build_path])
    Enum.each(statics, fn (%{source: source, target: target}) ->
      source_pathname = Path.join(source_path(), source)
      target_pathname = Path.join(build_path, target)
      Fermo.File.copy(source_pathname, target_pathname)
    end)
    put_in(config, [:stats, :copy_statics_completed], Time.utc_now)
  end
end
