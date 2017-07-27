defmodule Fermo.Helpers.Assets do
  @doc false
  defmacro __using__(_opts \\ %{}) do
    quote do
      require Fermo.Helpers.Assets

      def image_path(filename) do
        "/images/#{filename}"
      end

      def image_tag(filename, attributes \\ []) do
        attribs = Enum.map(attributes, fn ({k, v}) ->
          "#{k}=\"#{v}\""
        end)
        "<img src=\"#{image_path(filename)}\" #{Enum.join(attribs, " ")}/>"
      end

      def javascript_path(name) do
        "/javascripts/#{name}.js"
      end

      def javascript_include_tag(name) do
        "<script src=\"#{javascript_path(name)}\" type=\"text/javascript\"></script>"
      end

      def stylesheet_path(name) do
        "/stylesheets/#{name}.css"
      end

      def stylesheet_link_tag(name) do
        "<link href=\"#{stylesheet_path(name)}\" media=\"all\" rel=\"stylesheet\" />"
      end
    end
  end
end

