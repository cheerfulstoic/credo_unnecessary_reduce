
# TODO: reduce with acc ++ []

Benchee.run(
  %{
    "map" => fn list ->
      Enum.map(list, fn i -> i * i end)
    end,
    "stream: map" => fn list ->
      Stream.map(list, fn i -> i * i end)
      |> Enum.to_list()
    end,
    "reduce: map" => fn list ->
      Enum.reduce(list, [], fn i, result ->
        [i * i | result]
      end)
      |> Enum.reverse()
    end,
    "filter+map" => fn list ->
      list
      |> Enum.filter(& rem(&1, 2) == 0)
      |> Enum.map(& &1 * &1)
    end,
    "stream: filter+map" => fn list ->
      list
      |> Stream.filter(& rem(&1, 2) == 0)
      |> Stream.map(& &1 * &1)
      |> Enum.to_list()
    end,
    "reduce: filter+map" => fn list ->
      Enum.reduce(list, [], fn i, result ->
        if rem(i, 2) == 0 do
          [i * i | result]
        else
          result
        end
      end)
      |> Enum.reverse()
    end
  },
  time: 2,
  # memory_time: 1,
  inputs: %{
      "10" => Enum.to_list(1..10),
      "100" => Enum.to_list(1..100),
      "1_000" => Enum.to_list(1..1_000),
      "10_000" => Enum.to_list(1..10_000),
      "100_000" => Enum.to_list(1..100_000),
      "1_000_000" => Enum.to_list(1..1_000_000)
    }
)

