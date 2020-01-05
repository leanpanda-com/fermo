defmodule Mix.Tasks.Fermo.Build do
  use Mix.Task

  @shortdoc "Generates the output files"

  @moduledoc """
  Builds the project according to the settings in priv/config.exs
  """
  def run(args) do
    {:ok, output} = Fermo.render("article_template.html.slim")
    IO.puts "output: #{output}"
  end
end
