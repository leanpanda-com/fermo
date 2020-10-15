defmodule Fermo.Live.Plug do
  import Plug.Conn
  import Mix.Fermo.Paths, only: [app_path: 0]

  def init(options) do
    options
  end

  def call(conn, _opts) do
    request_path = request_path(conn)
    with {:ok, request_build_path} = request_build_path(request_path),
         {:ok, full_path} <- full_path(request_build_path),
         {:ok, extension} = extension(full_path),
         mime_type <- mime_type(extension) do
      respond_with_file(conn, full_path, mime_type)
    else
      {:error, :illegal_path} ->
        respond_403(conn)
      {:error, :doesnt_exist} ->
        respond_404(conn)
      {:error, :unexpected_extname_result} ->
        respond_500(conn)
    end
  end

  defp respond_403(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(403, "Forbidden")
  end

  defp respond_404(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "Not found")
  end

  defp respond_500(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(500, "Application error")
  end

  defp respond_with_file(conn, full_path, mime_type) do
    conn
    |> put_resp_content_type(mime_type)
    |> send_resp(200, File.read!(full_path))
  end

  defp request_path(conn), do: conn.request_path

  defp build_root do
    Path.join(app_path(), "build")
    |> Path.expand()
  end

  # Illegal paths contain more ".." elements
  # than other elements and result in paths
  # outside of the build directory
  defp request_build_path(path) do
    build_root = build_root()
    full = Path.join(build_root, path)
    expanded = Path.expand(full)
    if String.starts_with?(expanded, build_root) do
      {:ok, full}
    else
      {:error, :illegal_path}
    end
  end

  # If the path ends in /, look for /index.html
  # etc
  defp full_path(path) do
    cond do
      File.regular?(path) ->
        {:ok, path}
      String.ends_with?(path, "/") && File.regular?(path <> "index.html") ->
        {:ok, path <> "index.html"}
      File.regular?(path <> "/index.html") ->
        {:ok, path <> "/index.html"}
      true ->
        {:error, :doesnt_exist}
    end
  end

  defp extension(path) do
    maybe_with_dot = Path.extname(path)
    cond do
      maybe_with_dot == "" ->
        {:ok, ""}
      maybe_with_dot == "." ->
        # We'll treat files with a final dot as HTML
        {:ok, ""}
      String.starts_with?(maybe_with_dot, ".") ->
        {:ok, String.slice(maybe_with_dot, 1..-1)}
      true ->
        {:error, :unexpected_extname_result}
    end
  end

  defp mime_type(extension) do
    case extension do
      "js" -> "application/javascript"
      "css" -> "text/css"
      "html" -> "text/html"
      "jpg" -> "image/jpeg"
      "jpeg" -> "image/jpeg"
      "pdf" -> "application/pdf"
      "png" -> "image/png"
      "txt" -> "text/plain"
      "xml" -> "application/xml"
      _ -> "text/html"
    end
  end
end
