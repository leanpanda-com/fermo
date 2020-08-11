defmodule Fermo.Sitemap do
  @xml_header ~s(<?xml version="1.0" encoding="UTF-8"?>\n)
  @open_tag ~S(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)
  @close_tag ~S(</urlset>)

  def build(%{sitemap: sitemap} = config) do
    root = config.base_url
    build_path = config[:build_path] || "build"
    sitemap_pathname = build_path <> "/sitemap.xml"
    datetime = FermoHelpers.DateTime.current_datetime()
    lastmod = FermoHelpers.DateTime.strftime!(datetime, "%Y-%m-%dT%H:%M:%S%z")

    config_defaults = %{
      lastmod: lastmod,
      change_frequency: sitemap[:default_change_frequency] || "weekly",
      priority: sitemap[:default_priority] || 0.5
    }

    File.write!(sitemap_pathname, @xml_header)
    File.write!(sitemap_pathname, @open_tag, [:append])

    Stream.map(config.pages, fn page ->
      module = Fermo.module_for_template(page.template)
      page_defaults = module.defaults()
      |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)

      values = Map.merge(config_defaults, page_defaults)
      if !page_defaults[:hide_from_sitemap] do
        loc = "#{root}#{page.target}"
        ~s(
          <url>
            <loc>#{loc}</loc>
            <lastmod>#{values.lastmod}</lastmod>
            <changefreq>#{values.change_frequency}</changefreq>
            <priority>#{values.priority}</priority>
          </url>
        )
      end
    end)
    |> Stream.filter(&(&1))
    |> Stream.into(File.stream!(sitemap_pathname, [:append, :utf8]))
    |> Stream.run()

    File.write!(sitemap_pathname, @close_tag, [:append])
    put_in(config, [:stats, :sitemap_built], Time.utc_now)
  end
  def build(config), do: config
end
