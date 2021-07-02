defmodule Fermo.Paths do
  def filename_to_path(path, opts \\ [])
  def filename_to_path(filename, as_index_html: true) do
    cond do
      filename == "index.html" ->
        "/"
      String.ends_with?(filename, "/index.html") ->
        String.replace(filename, "index.html", "")
      String.ends_with?(filename, ".html") ->
        String.replace(filename, ".html", "")
      true ->
        filename
    end
  end
  def filename_to_path(path, _opts), do: path

  def path_to_filename(path, opts \\ [])
  def path_to_filename(path, as_index_html: false), do: path
  def path_to_filename(path, _opts) do
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

  def template_to_filename(template, opts) do
    without_templating_extension = String.replace(template, ~r(\.[a-z]+$), "")

    path_to_filename(without_templating_extension, opts)
  end
end
