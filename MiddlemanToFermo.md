# Automatic Conversion of Middleman Projects

Run the following, indicating the directory containing
your existing Middleman SLIM files, and a destination directory.

```sh
$ mix fermo.middleman_importer \
  --source middleman_project/source \
  --destination fermo_project/priv/source
```

Your .slim files will get copied and updated to make them
work with Elixir SLIM.

# About Elixir

## Elixir does not have mutable data structures

This means that you can't update things like Maps or Lists

## Elixir does not have classes and objects

There's no such thing as an instance of a class. Most of the
time you work with the data structures that the language supplies.

## Data Structures

* Map is like Ruby's Hash,
* List is like Ruby's Array.

## Elixir is a compiled language

Before creating your Fermo pages, your project needs to be compiled.
If there are errors in your SLIM templates, compilation will fail.

# Fermo and SLIM

Fermo uses `slime` - a SLIM implementation in Elixir.

Compared to the Ruby implementation:

* SLIME doesn't support `=>` or `=<`,
* `each` should be replaced by `Enum.map`,
* `if` and `Enum.map` should be preceded by `=`,
* Partial parameters should be surrounded by `%{}`,
* In partials, `locals:` is not available, get values from `params`,
* The `locale` is included in the `context` as `context.page.options.locale`
  and cannot be obtained from `I18n.locale`,
* Use `params.content` in layouts instead of `yield`.

# Converting Ruby SLIM to Elixir Slime

* convert partial calls:

```slim
head= partial "head", locals: {foo: true}
```

```slime
head= partial("head", %{foo: true})
```

* rename '.html' -> '.html.slim',
* I18n.locale -> context.locale,
* current_page.url -> ??,
* `- if ...` - see below,
* `- each` - see below,
* convert old asset pipelines to Webpack,
* convert any coffeescript to javascript,
* in layouts `= yield` -> `= content`,
* replace `=>` `=<` with `=`,
* replace `current_page.data.foo` with `params.foo`.

# if

```
= if value do
  It's true!
```

With else:

```
= if value do
  It's true!
- else
  It's not true.
```

Inline:

```
- message = if value, do: "True", else: "False"
```

# Handling Collections

Create a block for each item in a list:

```
= Enum.map things, fn thing ->
  = thing.name
```

Include the list index:

```
= Enum.map Enum.with_index(things), fn {thing, i} ->
  = i
  = thing.name
```

# Libraries

Here are some example of replacements for common Ruby Gems used in
Middleman projects:

* i18n - included in Fermo (see Fermo.i18n)

# HOWTOs

## REST APIs

If an API has a JSON Schema, use `json_hyperschema_client_builder`,
which will generate a whole Elixir API library for you.

# Middleman and DatoCMS

## With the GraphQL client

* `dato.foo.bar` -> `fetch!(:foo, "{ bar }").bar`,
* `dato.foos` -> `fetch_all!(:allFoos, "{ bar }")`.
