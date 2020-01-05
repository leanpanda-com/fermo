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
