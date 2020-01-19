# Fermo

# Usage

1. Create an Elixir project:

```sh
$ mix new myProject
```

2. Modify `mix.exs`

Configure the compiler:

```elixir
  def project do
    [
      ...
      compilers: Mix.compilers() ++ [:fermo],
      ...
    ]
  end
```

Add the dependency:

```elixir
{:fermo, "~> 0.2.1"}
```

3. Get dependencies:

```sh
$ mix deps.get
```

4. Create `lib/{{project name}}.ex`:

```elixir
defmodule MyProject do
  @moduledoc """
  Documentation for MyProject.
  """

  use Fermo, %{
    exclude: ["templates/*", "layouts/*", "javascripts/*", "stylesheets/*"],
    i18n: [:it, :en]
  }

  def build do
    config = config()

    Fermo.build(config)
  end
end
```

5. Build the project:

```sh
$ mix fermo.build
```

# Capabilities

* build your projects fast, using all available cores,
* handle Middleman-like config-time defined pages (see below),

# Config-time Pages

Most static site generators build one webpage for every source page
(e.g. Hugo).

Middleman provides the very powerful but strangely named `proxy`,
which allows you to produce many pages from one template.
So, if you have a local JSON of YAML file, or even better an online
CMS, as a source, you can build a page for each of your items
without having to commit the to your Git repo.

In Fermo, dynamic, data-based pages are created with the `page` method.

# Templates

Currently, Fermo only supports SLIM templates for HTML.

## Parameters

Top level pages are called with the following parameters:

* `params` - the parameters passed directly to the template or partial,
* `context` - hash of contextual information.

### Context

* `:env` - the application environment,
* `:template` - the top-level page or partial template pathname, with path
  relative to the source root,
* `:page` - see below.

### Page

Information about the top-level page.

* `:template` - the template path and name relative to the source root,
* `:target` - the path of the generated file,
* `:params` - the parameters passed to the template,
* `:options` - other options, e.g. the locale.

## Partials

Partials are also called with the same 2 parameters, but the values in `:page`
are those of the top-level page, not the partial itself.

# Helpers

Helpers related to the asset pipeline are provided directly by
Fermo - see below.

Fermo also provides various helpers via the [fermo_helpers] library.

## Timezone Information

Note: If you want to use `current_datetime/1`, you need to include
the following dependency:

```elixir
{:tzdata, "~> 1.0"}
```

and add a config option

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

[fermo_helpers]: https://hexdocs.pm/fermo_helpers/FermoHelpers.html

# Assets

Webpack-based assets can be integrated with the Fermo build.

Your config should product a manifest as `build/manifest.json`:

```js
const ManifestPlugin = require('webpack-manifest-plugin')

module.exports = {
  ..
  output: {
    path: __dirname + '/build',
    ...
  },
  ...
  plugins: [
    ...
    new ManifestPlugin()
  ]
}
```

Run the Webpack build:

```elixir
config = Fermo.Assets.build(config)
```

## Asset Helpers

You can then use the helpers provided by `Fermo.Helpers.Assets`
such as `javascript_include_tag` and you will pick up the
correctly hashed filenames.

# Middleman to Fermo

Fermo was created as an improvement on Middleman, so it's defaults
tend to be the same its progenitor.

See [here](MiddlemanToFermo.md).

# Fermo and DatoCMS

## With the GraphQL client

* single items: `fetch!(:foo, "{ bar }").bar`,
* localized single items: `fetch_localized!(:foo, :en, "{ bar }")`,
* collections: `fetch_all!(:allFoos, "{ bar }")`,
* localized collections: `fetch_all_localized!(:allFoos, :en, "{ bar }")`.
