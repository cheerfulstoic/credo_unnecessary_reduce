# CredoUnnecessaryReduce

From the docs for `Enum.reduce/3`:

> When an operation cannot be expressed by any of the functions in the Enum module, developers will most likely resort to reduce/3.

-----

This library implements a custom [credo](https://github.com/rrrene/credo) check which looks for opportunities to refactor usage of `Enum.reduce` into other `Enum` functions (and `Map.new`!).

The goal is both to:

* identify places where code could be simpler
* help people learn about variety of useful functions that exist in Elixir's `Enum` module

See also [Motivation](https://github.com/cheerfulstoic/credo_unnecessary_reduce/wiki/Motivation) in the wiki.

## Examples

For example, the following cases would be detected:

```elixir
Enum.reduce(numbers, [], fn i, result -> [i * 10 | result] end)
|> Enum.reverse()

# The `++` is another way to build a list in Elixir, but because of the way lists are 
# stored, it's much more efficient to prepend and then reverse.
Enum.reduce(numbers, [], fn i, result -> result ++ [i * 10] end)
```

Both of these cases could be replaced by a `Enum.map(numbers, &(&1 * 10))`

For a different example:

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

That whole block could be replaced by `Enum.filter(numbers, &(rem(number, 2) == 0))`.

Currently this library checks for cases of `Enum.reduce` which could be replaced by:

* `Enum.any?`
* `Enum.all?`
* `Enum.filter`
* `Enum.flat_map`
* `Enum.map`
* `Enum.product`
* `Enum.product_by`
* `Enum.reject`
* `Enum.sum`
* `Enum.sum_by`
* `Enum.count`
* `Enum.split_with`
* `Map.new`

See [Examples](https://github.com/cheerfulstoic/credo_unnecessary_reduce/wiki/Examples) for specific cases of code that is detected.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `credo_unnecessary_reduce` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:credo_unnecessary_reduce, "~> 0.3.0"}
  ]
end
```

You can enable the check by adding it to your `.credo.exs` file under the `checks` section:

```elixir
[
  checks: [
    # Other checks...
    {CredoUnnecessaryReduce.Check, []}
  ]
]

## Combination cases

Sometimes an `Enum.reduce` call will be doing more than one thing at a time.  For example it's very common to have a `reduce` can be replaced by an `Enum.filter` piped into an `Enum.map`:

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

In this case the `credo_unnecessary_reduce` check will just recommend replacing with the outermost pattern in can detect (`Enum.filter` in this case).  It may be possible to support suggesting the whole chain, but because of the complexity of that challenge it's enough for now that `Enum.reduce` calls that can be simplified are identified successfully.

## Current Limitations

The check currently detects and suggests replacements for certain patterns of `Enum.reduce`. However, it may not suggest the full chain of refactors, especially in complex combinations where multiple operations are performed in sequence.

## Bugs

This library is designed to lean on the side of triggering **only when a use of reduce would be better served by another function**.  This means that there are some cases it will never be able to catch.

Also, it's possible that it may catch cases which don't necessarily need to be replaced.  If you could make an argument that `reduce` is better, that could be a bug and a GitHub issue would be welcome!

## TODO

Potential low hanging fruit:

* `Enum.count_until`
* `Enum.frequencies`
* `Enum.frequencies_by`
* `Enum.max`
* `Enum.max_by`
* `Enum.min`
* `Enum.min_by`

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
be found at <https://hexdocs.pm/credo_unnecessary_reduce>.
