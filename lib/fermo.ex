defmodule Fermo do
  def render(path) do
    templates_path = "priv/source/templates"
    full_path = Path.join(templates_path, path)
    {:ok, source} = File.read(full_path)
    [frontmatter, body] = String.split(source, "---\n")
    params = YamlElixir.read_from_string(frontmatter)
    params_keywords = keyword_list(params)
    {:ok, Slime.render(body, params_keywords)}
  end

  defp keyword_list(map) when is_map(map) do
    Enum.map(map, fn({key, value}) -> {String.to_atom(key), value} end)
  end
end
