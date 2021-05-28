defmodule Fermo.Assets do
  @webpack_dev_server_port 8080

  def start_link(args \\ []) do
    Webpack.Assets.start_link(args)
  end

  def build() do
    Webpack.Assets.build()
  end

  defmacro asset_path(name) do
    quote do
      context = var!(context)
      if context[:page][:live] do
        live_asset_path(unquote(name))
      else
        static_asset_path(unquote(name))
      end
    end
  end

  def static_asset_path("https://" <> _path = url) do
    url
  end
  def static_asset_path(filename) do
    Webpack.Assets.path!(filename)
  end

  def live_asset_path(filename) do
    "//localhost:#{@webpack_dev_server_port}/#{filename}"
  end

  # TODO: make this a context aware macro
  def font_path("https://" <> _path = url) do
    url
  end
  def font_path(filename) do
    Webpack.Assets.path!("/fonts/#{filename}")
  end

  defmacro image_path("https://" <> _path = url) do
    quote do
      static_image_path(unquote(url))
    end
  end
  defmacro image_path(name) do
    quote do
      context = var!(context)
      if context[:page][:live] do
        live_image_path(unquote(name))
      else
        static_image_path(unquote(name))
      end
    end
  end

  defmacro image_tag(filename, attributes) do
    quote do
      if String.starts_with?(unquote(filename), "https://") do
        image_tag_with_attributes(unquote(filename), unquote(attributes))
      else
        context = var!(context)
        url = if context[:page][:live] do
          live_image_path(unquote(filename))
        else
          static_image_path(unquote(filename))
        end
        image_tag_with_attributes(url, unquote(attributes))
      end
    end
  end

  def image_tag_with_attributes(url, attributes) do
    attribs = Enum.map(attributes, fn ({k, v}) ->
      "#{k}=\"#{v}\""
    end)

    "<img src=\"#{url}\" #{Enum.join(attribs, " ")}/>"
  end

  def static_image_path("https://" <> _path = url) do
    url
  end
  def static_image_path("/" <> filename) do
    Webpack.Assets.path!("/images/#{filename}")
  end
  def static_image_path(filename) do
    Webpack.Assets.path!("/images/#{filename}")
  end

  def live_image_path(filename) do
    "//localhost:#{@webpack_dev_server_port}/images/#{filename}"
  end

  defmacro javascript_path(name) do
    quote do
      context = var!(context)
      if context[:page][:live] do
        live_javascript_path(unquote(name))
      else
        static_javascript_path(unquote(name))
      end
    end
  end

  defmacro javascript_include_tag(name) do
    quote do
      context = var!(context)
      url = if context[:page][:live] do
        live_javascript_path(unquote(name))
      else
        static_javascript_path(unquote(name))
      end
      "<script src=\"#{url}\" type=\"text/javascript\"></script>"
    end
  end

  def static_javascript_path("https://" <> _path = url) do
    url
  end
  def static_javascript_path(name) do
    Webpack.Assets.path!("/#{name}.js")
  end

  def live_javascript_path(name) do
    "//localhost:#{@webpack_dev_server_port}/javascripts/#{name}.js"
  end

  defmacro stylesheet_link_tag(name) do
    quote do
      context = var!(context)
      url = if context[:page][:live] do
        live_stylesheet_path(unquote(name))
      else
        static_stylesheet_path(unquote(name))
      end
      "<link href=\"#{url}\" media=\"all\" rel=\"stylesheet\" />"
    end
  end

  def static_stylesheet_path("https://" <> _path = url) do
    url
  end
  def static_stylesheet_path(name) do
    Webpack.Assets.path!("/#{name}.css")
  end

  def live_stylesheet_path(name) do
    "//localhost:#{@webpack_dev_server_port}/stylesheets/#{name}.css"
  end
end
