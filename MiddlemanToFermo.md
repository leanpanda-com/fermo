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

[LINK A ELIXIR DOCS]

## Data Structures

* Map is like Ruby's Hash,
* List is like Ruby's Array.

## Elixir does not have classes and objects

There's no such thing as an instance of a class. Most of the
time you work with functions, Maps and Lists.

## Elixir does not have mutable data structures

This means that you can't update things like Maps or Lists, you
make modified copies.

## Elixir is a compiled language

Before creating your Fermo pages, your project needs to be compiled.
If there are errors in your SLIM templates, compilation will fail.

# Fermo and SLIM

Fermo uses `slime` - a SLIM implementation in Elixir.

Compared to the Ruby implementation:

* `each` should be replaced by `Enum.map`,
* `if` and `Enum.map` should be preceded by `=` instead `-`,
* Partial parameters should be surrounded by `%{}` instead of `{}`,
* Fermo passes two variables to SLIM templates: `params` and `context`,
  see [the main README](README.md) for info on these variables,
* In partials, `locals:` is not available, get values from `params`,
* The `locale` is included in the `context` as `context.page.options.locale`
  and cannot be obtained from `I18n.locale`,
* Use `params.content` in layouts instead of `yield`.

# Notes about Manual Conversions of Middleman to Fermo

* rename '.html' -> '.html.slim',
* convert old asset pipelines to Webpack,
* in layouts `= yield` -> `= params.content`,
* replace `current_page.data.foo` with `params.foo`.

## Handling Collections

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

# Comparisons of SLIM and SLIME

## `partial`

```slim
head= partial "head", locals: {foo: true}
```

```slime
head= partial("head", %{foo: true})
```

## `if`

```slim
- if value
  It's true!
```

```slime
= if value do
  It's true!
```

## `if` ... `else`

```slim
- if value
  It's true!
- else
  It's not true.
```

```slime
= if value do
  It's true!
- else
  It's not true.
```

## Ternary `if`

```slim
- message = value ? "True" : "False"
```

```slime
- message = if value, do: "True", else: "False"
```

## `if` post conditions

```slim
= squared_image(image: image, size: 70) if image.present?
```

```slime
= if image.present?
  = squared_image(image: image, size: 70)
```

# Libraries

Here are some example of replacements for common Ruby Gems used in
Middleman projects:

* i18n - included in Fermo (see Fermo.i18n)

# HOWTOs

## REST APIs

If an API has a JSON Schema, use `json_hyperschema_client_builder`,
which will generate a whole Elixir API library for you.
