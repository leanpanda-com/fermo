# Fermo and SLIM

Fermo uses `slime` - a SLIM implementation in Elixir.

There are some differences from other SLIM dialects:

Compared to the Ruby implementation:

* `if` and `Enum.map` should be preceded by `=`,
* Hash parameters `{}` should be surrounded by `%{}`.

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
