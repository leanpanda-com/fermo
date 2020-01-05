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
        attribs = Enum.map(attributes, fn ({k, v}) ->
          "#{k}=\"#{v}\""
        end)
        "<a href=\"#{href}\" #{Enum.join(attribs, " ")}>#{text}</a>"
      end

      def mail_to(email, caption \\ nil, _mail_options \\ %{}) do
        # TODO handle _mail_options
        mail_href = "mailto:#{email}"
        link_to((caption || email), mail_href)
      end
    end
  end
end
