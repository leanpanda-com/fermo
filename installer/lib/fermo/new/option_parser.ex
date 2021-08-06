defmodule Fermo.New.OptionParser do
  @strict [locales: :string]

  @callback run([String.t()]) ::
    {:ok, map()} |
    {:error, atom()} |
    {:error, atom(), String.t()}
  @doc ~S|
  Parse command-line arguments

    iex> Fermo.New.OptionParser.run(["/base/path"])
    {:ok, %{base_path: "/base/path"}}

  Locales can be supplied

    iex> Fermo.New.OptionParser.run(["--locales", "en,it", "/base/path"])
    {:ok, %{base_path: "/base/path", locales: ["en", "it"]}}

  The base path is required

    iex> Fermo.New.OptionParser.run(["--locales", "en,it"])
    {:error, :bad_args}

  Locales need to be well formed

    iex> Fermo.New.OptionParser.run(["--locales", "%%", "/base/path"])
    {:error, :bad_args, "Malformed locales parameter"}
  |
  def run(argv) do
    case OptionParser.parse(argv, strict: @strict) do
      {_opts, [], []} ->
        {:error, :bad_args}
      {options, [base_path], []} ->
        options
        |> Enum.into(%{})
        |> Map.put(:base_path, base_path)
        |> post_process_options()
      {_opts, _args, _errors} ->
        {:error, :bad_args}
    end
  end

  defp post_process_options(options) do
    case extract_locales(options) do
      {:ok} ->
        {:ok, options}
      {:ok, locales} ->
        {:ok, Map.put(options, :locales, locales)}
      {:error, error, message} ->
        {:error, error, message}
    end
  end

  defp extract_locales(%{locales: locales}) do
    if locales =~ Regex.recompile!(~r/^[a-z]{2}(,[a-z]{2})*$/) do
      {:ok, String.split(locales, ",")}
    else
      {:error, :bad_args, "Malformed locales parameter"}
    end
  end
  defp extract_locales(_options), do: {:ok}
end
