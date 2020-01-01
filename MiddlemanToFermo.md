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

Inline (inline):

```
- message = if value, do: "True", else: "False"
```

# Collections

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

# Middleman and DatoCMS

* `dato.foo.bar` -> `fetch!(:foo, "{ bar }").bar`,
* `dato.foos` -> `fetch_all!(:allFoos, "{ bar }")`.
