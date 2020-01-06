defmodule Fermo.Naming do
  def source_path_to_module(path) do
    base =
      path
      |> String.replace(~r/\.html\.slim$/, "")
      |> String.replace("/", ".")
    upper = Regex.replace(~r/(?:\b|\.)([a-z])/, base, &(String.upcase(&1)))
    :"Elixir.Fermo.Template.#{upper}"
  end
end
