defmodule Fermo.Pagination do
  def paginate(config, template, items, base_params \\ %{}, options \\ %{}) do
    # Remove existing single page from config.pages
    pages = Map.get(config, :pages, [])
    pages = Enum.filter(pages, fn (%{template: t}) -> t != template end)

    total_items = length(items)
    per_page = 10 # TODO: how many?
    page_count = (total_items - 1) / per_page + 1

    base = base_path(template)

    paginated = Stream.chunk(items, per_page, per_page, [])
    |> Stream.with_index
    |> Enum.map(fn ({chunk, i}) ->
      # index is 1 based
      index = i + 1
      params = %{
        pagination: %{
          items: chunk,
          page: index,
          prev_page: page_url(base, index - 1, page_count),
          next_page: page_url(base, index + 1, page_count)
        }
      }
      Fermo.page_from(
        template,
        page_path(base, index, page_count),
        Map.merge(params, base_params),
        options
      )
    end)
    put_in(config, [:pages], pages ++ paginated)
  end

  defp base_path("index.html.slim"), do: ""
  defp base_path(template) do
    cond do
      String.ends_with?(template, "/index.html.slim") ->
        String.trim_trailing(template, "/index.html.slim")
      String.ends_with?(template, ".html.slim") ->
        String.trim_trailing(template, ".html.slim")
    end
  end

  def page_url(base, index, page_count) do
    page_path(base, index, page_count) |> path_to_url
  end

  def path_to_url(nil), do: nil
  def path_to_url(path), do: %{url: "/" <> path}

  defp page_path(_base, index, _page_count) when index < 1, do: nil
  defp page_path(_base, 1, 0), do: nil
  defp page_path(base, 1, _page_count), do: base <> "/index.html"
  defp page_path(_base, index, page_count) when index > page_count, do: nil
  defp page_path(base, index, _page_count), do: base <> "/pages/#{index}.html"
end
