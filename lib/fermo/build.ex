defmodule Fermo.Build do
  @moduledoc false

  import Mix.Fermo.Paths, only: [source_path: 0]

  @callback run(map()) :: {:ok, map()}
  def run(config) do
    # TODO: check if Webpack assets are ready before building HTML
    config = put_in(config, [:stats, :build_started], Time.utc_now)

    {:ok} = Fermo.Assets.build()
    {:ok} = Fermo.I18n.load()

    File.mkdir_p!(config.build_path)

    config =
      config
      |> Fermo.Config.post_config()
      |> copy_statics()
      |> Fermo.Sitemap.build()

    Task.async_stream(
      config.pages,
      &(render_cache_and_save(&1)),
      [timeout: :infinity]
    ) |> Enum.to_list

    config = put_in(config, [:stats, :build_completed], Time.utc_now)

    {:ok, config}
  end

  def render_page(page) do
    content = render_body(page.params.module, page)

    if page.params.layout do
      build_layout_with_content(page.params.layout, content, page)
    else
      content
    end
  end

  defp copy_statics(config) do
    statics = Map.get(config, :statics, [])
    build_path = config.build_path
    Enum.each(statics, fn (%{source: source, target: target}) ->
      source_pathname = Path.join(source_path(), source)
      target_pathname = Path.join(build_path, target)
      Fermo.File.copy(source_pathname, target_pathname)
    end)
    put_in(config, [:stats, :copy_statics_completed], Time.utc_now)
  end

  defp render_cache_and_save(page) do
    with {:ok, hash} <- cache_key(page),
      {:ok, cache_pathname} <- cached_page_path(hash),
      {:ok} <- is_cached?(cache_pathname) do
      Fermo.File.copy(cache_pathname, page.pathname)
    else
      {:build_and_cache, cache_pathname} ->
        body = render_page(page)
        Fermo.File.save(cache_pathname, body)
        Fermo.File.save(page.pathname, body)
      {:no_key} ->
        body = render_page(page)
        Fermo.File.save(page.pathname, body)
    end
  end

  defp cache_key(%{params: %{surrogate_key: nil}}), do: {:no_key}
  defp cache_key(%{params: %{surrogate_key: surrogate_key}}) do
    hash = :crypto.hash(:sha256, surrogate_key) |> Base.encode16
    {:ok, hash}
  end
  defp cache_key(_page), do: {:no_key}

  defp cached_page_path(hash) do
    {:ok, Path.join("tmp/page_cache", hash)}
  end

  defp is_cached?(cached_pathname) do
    if File.regular?(cached_pathname) do
      {:ok}
    else
      {:build_and_cache, cached_pathname}
    end
  end

  defp render_body(module, %{template: template} = page) do
    params = Fermo.Template.params_for(module, page)
    Fermo.Template.render_template(module, template, page, params)
  end

  defp build_layout_with_content(layout, content, page) do
    module = Fermo.Template.module_for_template(layout)
    layout_params = Map.merge(page.params, %{content: content})
    Fermo.Template.render_template(module, layout, page, layout_params)
  end
end
