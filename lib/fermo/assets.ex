defmodule Fermo.Assets do
  def start_link() do
    Webpack.Assets.start_link()
  end

  def build() do
    Webpack.Assets.build()
  end

  def asset_path(filename) do
    Webpack.Assets.path!(filename)
  end

  def font_path(filename) do
    Webpack.Assets.path!("fonts/#{filename}")
  end

  def image_path("https://" <> _path = url) do
    url
  end
  def image_path("/" <> filename) do
    Webpack.Assets.path!("/images/#{filename}")
  end
  def image_path(filename) do
    Webpack.Assets.path!("/images/#{filename}")
  end

  def javascript_path(name) do
    Webpack.Assets.path!("#{name}.js")
  end

  def stylesheet_path(name) do
    Webpack.Assets.path!("#{name}.css")
  end

  def image_tag(filename, attributes \\ []) do
    attribs = Enum.map(attributes, fn ({k, v}) ->
      "#{k}=\"#{v}\""
    end)
    "<img src=\"#{image_path(filename)}\" #{Enum.join(attribs, " ")}/>"
  end

  def javascript_include_tag("https://" <> _path = url) do
    "<script src=\"#{url}\" type=\"text/javascript\"></script>"
  end
  def javascript_include_tag(name) do
    "<script src=\"#{javascript_path(name)}\" type=\"text/javascript\"></script>"
  end

  def stylesheet_link_tag(name) do
    "<link href=\"#{stylesheet_path(name)}\" media=\"all\" rel=\"stylesheet\" />"
  end
end
