# Fermo

A static site generator, build for speed and flexibility.

# Usage

1. Create an Elixir project:

```sh
$ mix new myProject
```

2. Modify `mix.exs`

See [Mix configuration](#mix-configuration).

3. Get dependencies:

```sh
$ mix deps.get
```

4. Create `lib/{{project name}}.ex`

See [Configuration](#configuration).

5. Build the project:

```sh
$ mix fermo.build
```

# Live Dev Mode

Have pages reloaded when structure, style or content change.

```sh
$ FERMO_LIVE=true mix fermo.live
```

The live site is available at http://localhost:4001/

When pages are requested,
the server injects a JS that starts a socket,
on the Elixir side, the socket registers the path that
the browser is visiting.

When changes happen to pages that are being visited,
the browser is told to reload the page via the websocket.

# Capabilities

* build your projects fast, using all available cores,
* handle Middleman-like [config-defined pages](#config-defined-pages),
* create [sitemaps](#sitemaps),
* handle localized pages,
* use an integrated [Webpack asset pipeline](#webpack-asset-pipeline).

# Project Structure

```
+-- build             - The built site
+-- lib
|   +-- my_project.ex - See [Configuration](#configuration)
|   +-- helpers.ex
+-- mix.exs           - See [Mix configuration](#mix-configuration)
+-- priv
    +-- locales       - See [Localization](#localization)
    |   +-- en.yml
    |   +-- ...
    +-- source
        +-- javascripts
        +-- layouts
        +-- localizable
        +-- templates
        +-- partials
        +-- static
        +-- stylesheets
        +-- templates
```

# Mix Configuration

```elixir
defmodule MyProject.MixProject do
  use Mix.Project

  def project do
    [
      ...
      compilers: Mix.compilers() ++ [:fermo],
      ...
      deps: deps()
    ]
  end

  defp deps do
    [
      {:fermo, "~> 0.5.1"}
    ]
  end
end
```

# Configuration

Create a module (under lib) with a name matching your MixProject module defined in
`[mix.exs](#mix-configuration)`.

This module must implement `build/0`, a function that returns an updated
`[config](#config-object)`.

```elixir
defmodule MyProject do
  @moduledoc """
  Documentation for MyProject.
  """

  use Fermo

  def build do
    config = initial_config()

    {:ok, config}
  end
end
```

# Fermo Invocation

The command

```elixir
use Fermo
```

prepares the initial `config` structure.

## Simple Excludes

In order to not have your template files automatically built as [simple files](#simple)
use `:exclude`.

```elixir
  use Fermo, %{
    exclude: ["templates/*", "layouts/*", "javascripts/*", "stylesheets/*"],
  }
```

# Config-defined Pages

Most static site generators build one webpage for every source page
(e.g. Hugo).

Middleman provides the very powerful but strangely named `proxy`,
which allows you to produce many pages from one template.
So, if you have a local JSON of YAML file, or even better an online
CMS, as a source, you can build a page for each of your items
without having to commit the to your Git repo.

In Fermo, dynamic, data-based pages are created with the `page` method in
your project configuration's `build/0` method.

```elixir
  def build do
    ...
    foo = ... # loaded from some external source
    page(
      config,
      "templates/foo.html.slim",
      "/foos/#{foo.slug}/index.html",
      %{foo: foo},
      %{locale: :en}
    )
    ...
  end
```

# Templating

Currently, Fermo only supports SLIM templates for HTML.

There are various types of templates:
* simple templates - any templates found under `priv/source` will be built. The `partials`
  directory is exluded by default - see [excludes](#excludes).
* page templates - used with [config-defined pages](#config-defined-pages),
* partials - used from other templates,
* localized - build for each configured locale. See [localization](#localization)

## Parameters

Top level pages are called with the following parameters:

* `params` - the parameters passed directly to the template or partial,
* `context` - hash of contextual information.

### Context

* `:env` - the application environment,
* `:module` - the module of the compiled template,
* `:template` - the top-level page or partial template pathname, with path
  relative to the source root,
* `:page` - see below.

### Page

Information about the top-level page.

* `:template` - the template path and name relative to the source root,
* `:target` - the path of the generated file,
* `:path` - the online path of the page,
* `:params` - the parameters passed to the template,
* `:options` - other options, e.g. the locale.

## Partials

Partials are also called with the same 2 parameters, but the values in `:page`
are those of the top-level page, not the partial itself.

# Associated Libraries

* [DatoCMS GraphQL Client][GraphQL]
* [FermoHelpers][FermoHelpers]

[GraphQL]: https://hexdocs.pm/datocms_graphql_client.html
[FermoHelpers]: https://hexdocs.pm/fermo_helpers/FermoHelpers.html

# Localization

If you pass an `:i18n` key with a list of locales to Fermo,
your locale files will be loaded at build time and
files under `localizable` will be built for each locale.

```elixir
defmodule MyProject do
  @moduledoc """
  Documentation for MyProject.
  """

  use Fermo, %{
    ...
    i18n: [:en, :fr]
  }

  ...
end
```

## `:localized_paths`

Fermo can optionally create a mapping of translated paths for any
page.

This allows you to easily manage language switching UIs and alternate
language meta tags.

To activate localized_paths, you need to pass a flag in your initial
config:

```elixir
defmodule MyProject do
  use Fermo, %{
    ...
    i18n: [:en, :fr],
    path_map: true,
    ...
  }

  ...
end
```

Then ensure you pass an `:id` and `:locale` in the options parameter
of your Fermo.page/5 calls:

```elixir
Fermo.page(
  config,
  "templates/my_template.html.slim",
  "/posts/#{post.slug}/index.html",
  %{post: post},
  %{locale: :fr, id: "post-#{post.id}"}
)
```

When you do this, Fermo will collect together all pages with the same `:id`
so when your template is called, it will have a `:localized_paths` Map available:

```elixir
%{
  ...
  localized_paths: %{
    en: "/posts/about-localization",
    fr: "/posts/a-propos-de-la-localisation",
  }
}
```

You can then use `:localized_paths` to build create links between
the different language versions of a page.

You can do the same for non-dynamic localized pages too, by indicating
the id in the template's frontmatter:

```slim
---
id: my-localized-page
---
```

# Middleman to Fermo

Fermo was created as an improvement on Middleman, so its defaults
tend to be the same its progenitor.

See [here](MiddlemanToFermo.md).
