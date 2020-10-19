defmodule Fermo.Build do
  def run(config) do
    # TODO: check if Webpack assets are ready before building HTML
    # TODO: avoid passing config into tasks - decide the layout beforehand

    Task.async_stream(
      config.pages,
      &(render_cache_and_save(&1)),
      [timeout: :infinity]
    ) |> Enum.to_list

    put_in(config, [:stats, :build_pages_completed], Time.utc_now)
  end

  def render_page(page) do
    content = render_body(page.options.module, page)

    if page.options.layout do
      build_layout_with_content(page.options.layout, content, page)
    else
      content
    end
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
      _ ->
        body = render_page(page)
        Fermo.File.save(page.pathname, body)
    end
  end

  defp cache_key(%{options: %{surrogate_key: surrogate_key}}) do
    hash = :crypto.hash(:sha256, surrogate_key) |> Base.encode16
    {:ok, hash}
  end
  defp cache_key(_page), do: {:no_key}

  defp cached_page_path(hash) do
    {:ok, Path.join("tmp/page_cache", hash)}
  end

  defp is_cached?(cached_pathname) do
    if File.exists?(cached_pathname) do
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
