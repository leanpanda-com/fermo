defmodule TestProject do
  @moduledoc """
  Documentation for `TestProject`.
  """

  use Fermo, %{
    base_url: Application.fetch_env!(:fermo, :base_url),
    i18n: [:en, :it],
    exclude: ["templates/*", "layouts/*", "javascripts/*", "stylesheets/*"],
    sitemap: %{
      default_priority: 0.5,
      default_change_frequency: "weekly"
    },
  }
  import Fermo, only: [page: 4]

  use Helpers

  def config do
    config = initial_config()

    config = page(
      config,
      "/templates/home.html.slim",
      "/index.html",
      %{id: "home", locale: :en, page: %{title: "English title"}}
    )

    config = page(
      config,
      "/templates/home.html.slim",
      "/it/index.html",
      %{id: "home", locale: :it, page: %{title: "Titolo italiano"}}
    )

    foos = List.duplicate(%{foo: "Bar"}, 30)

    config = Fermo.paginate(
      config,
      "templates/foos_index.html.slim",
      %{
        items: foos,
        per_page: 15,
        base: "/foos/",
        suffix: "pages/:page.html",
        first: "index.html"
      },
      %{locale: :it}
    )

    {:ok, config}
  end
end
