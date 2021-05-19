defmodule Fermo.Live.Server do
  import Plug.Conn
  import Mix.Fermo.Paths, only: [app_path: 0]

  live_reload_js_path = Application.app_dir(:fermo, "priv/static/fermo-live.js.eex")
  @external_resource live_reload_js_path

  @live_reload_js EEx.eval_string("""
  <script type="text/javascript">
  #{File.read!(live_reload_js_path)}
  </script>
  """, env: System.get_env())

  def init(_options) do
    []
  end

  def call(conn, _state) do
    request_path(conn) |> handle_request_path(conn)
  end

  defp handle_request_path({:error, :request_path_missing}, conn) do
    respond_403(conn)
  end
  defp handle_request_path({:ok, request_path}, conn) do
    if is_static?(request_path) do
      serve_static(request_path, conn)
    else
      case find_page(request_path) do
        {:ok, page} ->
          serve_page(page, conn)
        _ ->
          respond_404(conn)
      end
    end
  end

  defp is_static?(path) do
    build_path = build_path(path)
    File.regular?(build_path)
  end

  defp serve_static(path, conn) do
    build_path = build_path(path)
    {:ok, extension} = extension(build_path)
    mime_type = mime_type(extension)
    respond_with_file(conn, build_path, mime_type)
  end

  defp find_page(request_path) do
    Fermo.Live.Dependencies.page_from_path(request_path)
  end

  defp serve_page(page, conn) do
    {:ok} = Fermo.Live.Dependencies.start_page(page.path)
    html = live_page(page)
    respond_with_html(conn, html)
  end

  defp live_page(page) do
    html = Fermo.Build.render_page(page)
    inject_reload(html)
  end

  defp inject_reload(html) do
    if has_body_close?(html) do
      [body | tail] = String.split(html, "</body>")
      Enum.join([body, @live_reload_js | tail], "\n")
    else
      Enum.join([html, @live_reload_js], "\n")
    end
  end

  defp has_body_close?(html) do
    String.contains?(html, "</body>")
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

  defp respond_with_file(conn, full_path, mime_type) do
    conn
    |> put_resp_content_type(mime_type)
    |> send_resp(200, File.read!(full_path))
  end

  defp respond_with_html(conn, html) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  defp request_path(conn) do
    case conn.request_path do
      nil -> {:error, :request_path_missing}
      _ ->
        expanded = Path.expand(conn.request_path)
        if expanded == "/" do
          {:ok, "/"}
        else
          {:ok, expanded <> "/"}
        end
    end
  end

  defp build_root do
    Path.join(app_path(), "build")
    |> Path.expand()
  end

  defp build_path(path) do
    Path.join(build_root(), path)
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
      "ico" -> "image/vnd.microsoft.icon"
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
