# Fermo

# Usage

Create an Elixir project.

Add the dependency to `mix.exs`:

```elixir
{:fermo, "~> 0.0.1"}
```

Get dependencies:

```shell
$ mix deps.get
```

Create `lib/{{project name}}.ex`:

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
    Fermo.build(config)
  end
end
```

Build the project:

```shell
$ mix fermo.build
```

# Approach

When a Fermo project is compiled, all pages (single pages, proxy templates
and partials) are located.

Pages which have a special function (e.g. templates and partials) are filtered
out and remaining pages are queued for conversion to HTML.

# Defaults

Fermo was build to mimic the behaviour of Middleman, so it's defaults
tend to be the same its progenitor.

A number of helper methods are provided (e.g. `javascript_include_tag`) to
allow easy porting of Middleman projects.

# Templates

Currently, fermo only supports SLIM templates for HTML.

## Parameters

Top level pages are called with the following parameters:

* `params` - the parameters passed to the template or partial,
* `context` - hash of contextual information.

### Context

* `:module` - the module which called `Fermo.build/0`,
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
