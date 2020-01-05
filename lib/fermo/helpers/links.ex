defmodule Fermo.Helpers.Links do
  @doc false
  defmacro __using__(_opts \\ %{}) do
    quote do
      require Fermo.Helpers.Links

      def link_to(href, [do: content] = other) do
        link_to(content, href, [])
      end
      def link_to(text, href) when is_binary(text) and is_binary(href) do
        "<a href=\"#{href}\">#{text}</a>"
      end

      def link_to(href, attributes, [do: content] = other) when is_binary(href) and is_list(attributes) do
        link_to(content, href, attributes)
      end
      def link_to(text, href, attributes) when is_binary(text) and is_binary(href) and is_list(attributes) do
        attribs = to_attributes(attributes)
        "<a href=\"#{href}\" #{Enum.join(attribs, " ")}>#{text}</a>"
      end

      defp to_attributes(attributes) do
        Enum.map(attributes, &(to_attribute(&1)))
      end

      defp to_attribute({k, v}) when is_binary(v) do
        "#{k}=\"#{v}\""
      end
      defp to_attribute({k, v}) when is_map(v) do
        Enum.reduce(v, [], fn {k2, v2}, acc ->
          "#{k}-#{k2}=\"#{v2}\""
        end)
      end

      def mail_to(email, caption \\ nil, _mail_options \\ %{}) do
        # TODO handle _mail_options
        mail_href = "mailto:#{email}"
        link_to((caption || email), mail_href)
      end
    end
  end
end
