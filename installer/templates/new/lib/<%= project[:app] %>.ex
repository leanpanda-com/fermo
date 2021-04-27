defmodule <%= @project[:module] %> do
  @moduledoc """
  Documentation for `<%= @project[:module] %>`.
  """

  use Fermo, %{
    base_url: Application.fetch_env!(:fermo, :base_url),
    i18n: [:en, :it],
    exclude: ["templates/*", "layouts/*", "javascripts/*", "stylesheets/*"]
  }
  import Fermo, only: [page: 5]

  use Helpers

  def config do
    DatoCMS.GraphQLClient.configure()

    config = initial_config()

    config = page(
      config,
      "/templates/home.html.slim",
      "/index.html",
      %{id: "home"},
      %{locale: :it}
    )

    config = page(
      config,
      "/templates/home.html.slim",
      "/index.html",
      %{id: "home"},
      %{locale: :it}
    )

    {:ok, config}
  end
end
