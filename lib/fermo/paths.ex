defmodule Fermo.Paths do
  def target_to_path(target) do
    cond do
      target == "index.html" -> "/"
      String.ends_with?(target, "/index.html") ->
        String.replace(target, "index.html", "")
      true -> target
    end
  end

  def path_to_target(path, opts \\ [])
  def path_to_target(path, as_index_html: false), do: path
  def path_to_target(path, _opts) do
    cond do
      path == "index.html" ->
        path
      String.ends_with?(path, "/index.html") ->
        path
      String.ends_with?(path, "/") ->
        path <> "index.html"
      String.ends_with?(path, ".html") ->
        String.replace(path, ".html", "/index.html")
      true ->
        path <> "/index.html"
    end
  end

  def template_to_target(template, opts) do
    String.replace(template, ".slim", "")
    |> path_to_target(opts)
  end
end
