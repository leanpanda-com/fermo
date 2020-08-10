defmodule Mix.Tasks.Fermo.Build do
  use Mix.Task

  @shortdoc "Generates the output files"

  @moduledoc """
  Builds the project according to the settings in __MODULE__.build()
  """
  def run(_args) do
    Mix.Task.run "app.start"
    module = Mix.Fermo.Module.module!()
    {:ok, config} = module.config()
    {:ok, config} = Fermo.build(config)
    stats = Map.get(config, :stats)
    if stats do
      do_log(stats)
    end
    {:ok}
  end

  defp do_log(stats) do
    phases =
      stats
      |> Enum.map(&(&1))
      |> Enum.sort(&(Time.compare(elem(&1, 1), elem(&2, 1)) == :lt))

    start = elem(hd(phases), 1)

    Enum.each(phases, fn {action, time} ->
      diff = Time.diff(time, start, :millisecond)
      IO.puts "#{diff}ms #{action} "
    end)
  end
end
