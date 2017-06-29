defmodule Fermo do
  require EEx
  require Slime

  def start(_start_type, _args \\ []) do
    I18n.start_link()
  end

  @doc false
  defmacro __using__(opts \\ %{}) do
    quote do
      require Fermo

      @before_compile Fermo
      Module.register_attribute __MODULE__, :config, persist: true
      @config unquote(opts)

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

      def image_tag(filename, attributes \\ []) do
        attribs = Enum.map(attributes, fn ({k, v}) ->
          "#{k}=\"#{v}\""
        end)
        "<img src=\"images/#{filename}\" #{Enum.join(attribs, " ")}/>"
      end

      def javascript_include_tag(name) do
        "/javascripts/#{name}.js"
      end

      def truncate_words(text, options \\ []) do
        length = options[:length] || 30
        omission = options[:omission] || "..."
        words = String.split(text)
        if length(words) <= length do
          text
        else
          incipit = Enum.slice(words, 0..length)
          Enum.join(incipit, " ") <> omission
        end
      end

      defp partials_path, do: "partials"

      def partial(name, params \\ %{}) do
        template = Path.join(partials_path(), "_#{name}.html.slim")
        name = String.to_atom(template)
        apply(__MODULE__, name, [params])
      end

      def current_locale do
        I18n.get_locale!()
      end

      def environment, do: "production" # TODO

      def t(key) do
        I18n.translate!(key)
      end
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    templates = File.cd!("priv/source", fn ->
      Path.wildcard("**/*.slim")
    end)
    defs = Enum.map(templates, fn (path) ->
      Fermo.deftemplate(path)
    end)

    config = Module.get_attribute(env.module, :config)
    exclude = Map.get(config, :exclude, []) ++ ["partials/*", "localizable/*"]
    exclude_matchers = Enum.map(exclude, fn (glob) ->
      single = String.replace(glob, "?", ".")
      multiple = String.replace(single, "*", ".*")
      Regex.compile!(multiple)
    end)

    config = Enum.reduce(templates, config, fn (template, config) ->
      skip = Enum.any?(exclude_matchers, fn (exclude) ->
        Regex.match?(exclude, template)
      end)
      if skip do
        config
      else
        target = String.replace(template, ".slim", "")
        Fermo.add_page(config, template, target)
      end
    end)

    locales = config[:i18n]
    default_locale = hd(locales)
    config = Enum.reduce(templates, config, fn (template, config) ->
      if String.starts_with?(template, "localizable/") do
        target = String.replace_prefix(template, "localizable/", "")
        target = String.replace(target, ".slim", "")
        Enum.reduce(locales, config, fn (locale, config) ->
          localized_target = if locale == default_locale do
              target
            else
              "#{locale}/#{target}"
            end
          Fermo.add_page(config, template, localized_target, %{locale: locale})
        end)
      else
        config
      end
    end)

    Module.put_attribute(env.module, :config, config)

    get_config = quote do
      def config() do
        hd(__MODULE__.__info__(:attributes)[:config])
      end
    end
    defs ++ [get_config]
  end

  def load_translations(config) do
    default_locale = hd(config[:i18n])
    files = Path.wildcard("priv/locales/**/*.yml")
    translations = Enum.reduce(files, %{}, fn (file, translations) ->
      content = YamlElixir.read_from_file(file)
      atom_keys = AtomMap.atom_map(content)
      Map.merge(translations, atom_keys)
    end)
    I18n.put(translations, default_locale)
  end

  defp source_path, do: "priv/source"
  defp build_path, do: "build"

  def deftemplate(template) do
    [frontmatter, body] = parse_template(template)
    body = String.replace(body, ~r/^[\s\r\n]*/, "")
    name = String.to_atom(template)
    quote bind_quoted: binding() do
      compiled =
        try do
          eex_source = Slime.Renderer.precompile(body)
          info = [file: template, line: 1]
          EEx.compile_string(eex_source, info)
        rescue
          e ->
            IO.puts "Failed to precompile template: '#{template}'"
          IO.puts "\nbody:\n#{body}\n"
          raise e
        catch
          e ->
            IO.puts "Failed to precompile template: '#{template}'"
          IO.puts "\nbody:\n#{body}\n"
          raise e
        end
      escaped_frontmatter = Macro.escape(frontmatter)
      args = [Macro.var(:params, nil)]

      # Define a method with the frontmatter, so we can merge with
      # params when the template is evaluated
      def unquote(:"#{name}-defaults")() do
        unquote(escaped_frontmatter)
      end

      def unquote(name)(unquote_splicing(args)) do
        unquote(compiled)
      end
    end
  end

  defmacro proxy(config, template, target, params \\ %{}) do
    quote bind_quoted: binding() do
      Fermo.add_page(config, template, target, params)
    end
  end

  def add_page(config, template, target, params \\ %{}, options \\ %{}) do
    pages = Map.get(config, :pages, [])
    page = %{
      template: template,
      target: target,
      params: params,
      options: options
    }
    put_in(config, [:pages], pages ++ [page])
  end

  defmacro build(config \\ %{}) do
    quote bind_quoted: binding() do
      Fermo.do_build(__MODULE__, config)
    end
  end

  def do_build(module, config) do
    {:ok} = Fermo.load_translations(config)

    pages = config[:pages]
    pages_with_body = Enum.map(pages, fn (%{template: template, params: params, options: options} = page) ->
      previous_locale = I18n.get_locale()
      locale = options[:locale]
      if locale do
        I18n.set_locale(locale)
      end
      body = build_page(module, template, params)
      I18n.set_locale(previous_locale)
      put_in(page, [:body], body)
    end)
    config = put_in(config, [:pages], pages_with_body)

    File.mkdir(build_path())

    pages = config[:pages]
    Enum.each(pages, fn (%{body: body, target: target}) ->
      pathname = Path.join(build_path(), target)
      path = Path.dirname(pathname)
      File.mkdir(path)
      File.write!(pathname, body, [:write])
    end)
    config
  end

  def build_page(module, template, params \\ %{}) do
    defaults_method = String.to_atom(template <> "-defaults")
    defaults = apply(module, defaults_method, [])
    args = Map.merge(defaults, params)
    name = String.to_atom(template)
    content = apply(module, name, [args])
    apply(module, :"layouts/layout.html.slim", [%{content: content}])
  end

  def parse_template(path) do
    File.read(full_template_path(path)) |> split_template
  end

  defp split_template({:ok, source = "---\n" <> _rest}) do
    [_, frontmatter_yaml, body] = String.split(source, "---\n")
    frontmatter = YamlElixir.read_from_string(frontmatter_yaml)
    [Macro.escape(frontmatter, unquote: true), body]
  end
  defp split_template({:ok, body}) do
    [Macro.escape(%{}, unquote: true), body]
  end

  defp full_template_path(path) do
    Path.join(source_path(), path)
  end
end
