defmodule Fermo do
  require EEx
  require Slime

  def build(config \\ %{}) do
    # TODO: build stuff that's not excluded
    # TODO: run external pipelines
    config
  end

  defp full_template_path(path) do
    Path.join(source_path(), path)
  end

  defp source_path, do: "priv/source"

  def proxy(conf, template, target, arguments \\ []) do
    [eex, frontmatter] = prepare_proxy(template)
    bindings = combine(frontmatter, arguments)
    output = EEx.eval_string(eex, bindings)

    resource = %{body: output, target: target}
    resources = Map.get(conf, :resources, [])
    put_in(conf, [:resources], resources ++ [resource])
  end

  defp prepare_proxy(template) do
    [frontmatter, body] = split_template(template)
    eex = Slime.Renderer.precompile(body)
    [eex, frontmatter]
  end

  defp split_template(path) do
    {:ok, source} = File.read(full_template_path(path))
    [frontmatter_yaml, body] = String.split(source, "---\n")
    frontmatter = YamlElixir.read_from_string(frontmatter_yaml)
    [frontmatter, body]
  end

  defp combine(list1, list2) do
    Keyword.merge(keyword_list(list1), keyword_list(list2), fn _k, _v1, v2 ->
      v2
    end)
  end

  def keyword_pair({key, value}) when is_atom(key) do
    {key, value}
  end
  def keyword_pair({key, value}) do
    {String.to_atom(key), value}
  end

  defp keyword_list(map) when is_map(map) do
    Enum.map(map, &__MODULE__.keyword_pair/1)
  end
  defp keyword_list(list), do: list
end
