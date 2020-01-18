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

# Approach

When a Fermo project is compiled, all pages (single pages, templates
and partials) are located. Pages which have a special function
(e.g. templates and partials) are filtered out and remaining pages
are queued for conversion to HTML.

Dynamic, data-based pages are created with the `page` method.

# Defaults

A number of helper methods are provided (e.g. `javascript_include_tag`).

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

## FermoHelpers.DateTime

* `current_datetime/1`
* `datetime_to_rfc2822/1`

If you want to use `current_datetime/1`, you need to include
the following dependency:

```elixir
{:tzdata, "~> 1.0"}
```
and add a config option

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

# Middleman to Fermo

Fermo was build to mimic the behaviour of Middleman, so it's defaults
tend to be the same its progenitor.

See [here](MiddlemanToFermo.md).

# Fermo and DatoCMS

## With the GraphQL client

* single items: `fetch!(:foo, "{ bar }").bar`,
* localized single items: `fetch_localized!(:foo, :en, "{ bar }")`,
* collections: `fetch_all!(:allFoos, "{ bar }")`,
* localized collections: `fetch_all_localzed!(:allFoos, :en, "{ bar }")`.

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

You can then use the helpers provided by `Fermo.Helpers.Assets`
such as `javascript_include_tag` and you will pick up the
correctly hashed filenames.
