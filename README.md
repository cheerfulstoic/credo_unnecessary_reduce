# CredoUnneccesaryReduce

From the docs for `Enum.reduce/3`:

> When an operation cannot be expressed by any of the functions in the Enum module, developers will most likely resort to reduce/3.

-----

This library implements a custom [credo](https://github.com/rrrene/credo) check which looks for opportunities to refactor usage of `Enum.reduce` into other `Enum` functions.

The goal is both to:

* identify places where code could be simpler
* help people learn about variety of useful functions that exist in Elixir's `Enum` module

See also [Motivation](https://github.com/cheerfulstoic/credo_unneccesary_reduce/wiki/Motivation) in the wiki.

## Examples

For example, the following would be detected and could be replaced by a `Enum.map(numbers, &(&1 * 10))`

```elixir
Enum.reduce(numbers, [], fn i, result -> [i * 10 | result] end)
|> Enum.reverse()
```

```elixir
Enum.reduce(numbers, [], fn i, result -> result ++ [i * 10] end)
```

While these examples could be replaced by `Enum.filter(numbers, &(rem(number, 2) == 0))`

```elixir
Enum.reduce(numbers, [], fn number, result ->
  if rem(number, 2) != 0 do
    result
  else
    [number | result]
  end
end)
|> Enum.reverse()
```

Currently this library checks for cases of `Enum.reduce` which could be replaced by:

* `Enum.any?`
* `Enum.all?`
* `Enum.filter`
* `Enum.flat_map`
* `Enum.map`
* `Enum.reject`
* `Enum.sum`
* `Enum.count`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `credo_unneccesary_reduce` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:credo_unneccesary_reduce, "~> 0.1.0"}
  ]
end
```

Then you should add `{CredoUnneccesaryReduce.Check, []},` to your `.credo.exs` file under the `enabled` section.

## Complex cases

Sometimes an `Enum.reduce` call will be doing more than one thing at a time.  For example, this code could be replaced by an `Enum.filter` piped into an `Enum.map`:

```elixir
Enum.reduce(numbers, [], fn item, acc ->
  if rem(item, 2) == 0 do
    [item * 2 | acc]
  else
    acc
  end
end)
|> Enum.reverse()
```

The split out version:

```elixir
numbers
|> Enum.filter(& rem(&1, 2) == 0)
|> Enum.map(& &1 * 2)
```

In this case the `credo_unneccesary_reduce` check will just recommend replacing with the outermost pattern in can detect (`Enum.filter` in this case).  It may be possible to support suggesting the whole chain, but because of the complexity of that challenge it's enough for now that `Enum.reduce` calls that can be simplified are identified successfully.

## TODO

Low hanging fruit:

* `Enum.count_until` (?)
* `Enum.frequencies` (?)
* `Enum.frequencies_by` (?)
* `Enum.max` (?)
* `Enum.max_by` (?)
* `Enum.min` (?)
* `Enum.min_by` (?)
* `Enum.product` (?)
* `Enum.product_by` (?)
* `Map.new`

Unsure right now, could be good:

* `Enum.find`
* `Enum.find_index`
* `Enum.find_value`
* `Enum.group_by`
* `Enum.into`
* `Enum.join`
* `Enum.min_max`
* `Enum.min_max_by`
* `Enum.uniq`
* `Enum.uniq_by`

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/credo_unneccesary_reduce>.
