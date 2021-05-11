defmodule Fermo.Config do
  @localizable Application.get_env(:fermo, :localizable, Fermo.Localizable)
  @simple Application.get_env(:fermo, :simple, Fermo.Simple)

  def initial(config) do
    build_path = config[:build_path] || "build"
    pages = config[:pages] || []
    statics = config[:statics] || []

    config
    |> put_in([:build_path], build_path)
    |> put_in([:pages], pages)
    |> put_in([:statics], statics)
    |> @localizable.add()
    |> @simple.add()
    |> put_in([:stats], %{})
    |> put_in([:stats, :start], Time.utc_now)
  end
end
