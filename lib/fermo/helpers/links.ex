defmodule Fermo.Helpers.Links do
  @doc false
  defmacro __using__(opts \\ %{}) do
    quote do
      require Fermo.Helpers.Links

      def link_to(href, attributes, [do: content] = other) when is_list(attributes) and is_list(other) do
        link_to(content, href, attributes)
      end
      def link_to(text, href, attributes) do
        attribs = Enum.map(attributes, fn ({k, v}) ->
          "#{k}=\"#{v}\""
        end)
        "<a href=\"#{href}\" #{Enum.join(attribs, " ")}>#{text}</a>"
      end
      def link_to(text, href) do
        link_to(text, href, [])
      end

      def mail_to(email, caption \\ nil, _mail_options \\ %{}) do
        # TODO handle _mail_options
        mail_href = "mailto:#{email}"
        link_to((caption || email), mail_href)
      end
    end
  end
end
