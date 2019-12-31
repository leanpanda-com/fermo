defmodule Fermo.MiddlemanImporter do
  @args_options [source: :string, destination: :string]

  def run(args) do
    {source, destination} = parse_args(args)
    ensure_directory(destination)
    sources =
      sources(source)
      |> to_relative(source)
    Enum.each(sources, &(import_slim(&1, source, destination)))
  end

  defp parse_args(args) do
    {opts, arguments, invalid} = OptionParser.parse(args, strict: @args_options)

    if arguments != [] do
      raise "Unexpected arguments found: #{inspect(arguments)}"
    end

    if invalid != [] do
      raise "Invalid options found: #{inspect(invalid)}"
    end

    source = opts[:source]
    destination = opts[:destination]

    if !File.dir?(source) do
      raise "Source directory '#{source}' does not exist"
    end

    {source, destination}
  end

  defp sources(source) do
    Path.wildcard(source <> "/**/*.slim")
  end

  defp to_relative(sources, source) do
    Enum.map(sources, &(Path.relative_to(&1, source)))
  end

  defp import_slim(pathname, source, destination) do
    source_pathname = Path.join(source, pathname)
    raw = File.read!(source_pathname)
    converted = convert(raw)
    destination_pathname = Path.join(destination, pathname)
    destination_directory = Path.dirname(destination_pathname)
    ensure_directory(destination_directory)
    File.write!(destination_pathname, converted, [:write])
  end

  defp convert(raw) do
    raw
    |> ifs
    |> eachs
    |> ts
  end

  @if_match ~r<(\s*)-\s*if(.*)>x

  # Match `  - foos.each do |foo|`
  @each_match ~r<
    (\s*)
    -\s*                # SLIM code escape
    ([\w_\.]+)          # a Ruby variable
    .each\s*            # each
    do\s*               # do
    \|([\w_]+)\|        # block parameters
  >x

  # Match `t("teh.label")`
  @translation_match ~r<
    \bt                 # t
    \(                  # (
    ['"]                # ' or "
    ([\w_\.]+)          # localized string identifier
    ['"]                # ' or "
    \)                  # )
  >x

  defp ifs(raw) do
    String.replace(raw, @if_match, "\\1= if\\2 do")
  end

  defp eachs(raw) do
    String.replace(raw, @each_match, "\\1= Enum.map \\2, fn \\3 ->")
  end

  defp ts(raw) do
    String.replace(raw, @translation_match, ~s<t("\\1", locale)>)
  end

  defp ensure_directory(path) do
    if !File.dir?(path) do
      File.mkdir_p!(path)
    end
  end
end
