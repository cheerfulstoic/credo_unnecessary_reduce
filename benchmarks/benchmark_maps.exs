
all_users =
  Enum.map(1..1_000_000, fn i ->
    %{name: "User #{i}", age: i}
  end)
  |> Enum.take_random(1_000_000)


# TODO: reduce with acc ++ []
Benchee.run(
  %{
    "map" => fn list ->
      Enum.map(list, fn user -> Map.put(user, :age, user.age + 1) end)
    end,
    "stream: map" => fn list ->
      Stream.map(list, fn user -> Map.put(user, :age, user.age + 1) end)
      |> Enum.to_list()
    end,
    "reduce+reverse: map" => fn list ->
      Enum.reduce(list, [], fn user, result ->
        [Map.put(user, :age, user.age + 1) | result]
      end)
      |> Enum.reverse()
    end,
    "reduce++: map" => fn list ->
      Enum.reduce(list, [], fn user, result ->
        result ++ [Map.put(user, :age, user.age + 1)]
      end)
      |> Enum.reverse()
    end
  },
  time: 2,
  # memory_time: 1,
  inputs: %{
      "10" => Enum.slice(all_users, 0, 10),
      "100" => Enum.slice(all_users, 0, 100),
      "1_000" => Enum.slice(all_users, 0, 1_000),
      "10_000" => Enum.slice(all_users, 0, 10_000),
      "100_000" => Enum.slice(all_users, 0, 100_000),
      "1_000_000" => Enum.slice(all_users, 0, 1_000_000)
    }
)

Benchee.run(
  %{
    "filter+map" => fn list ->
      list
      |> Enum.filter(& rem(&1.age, 2) == 0)
      |> Enum.map(& Map.put(&1, :age, &1.age + 1))
    end,
    "stream: filter+map" => fn list ->
      list
      |> Stream.filter(& rem(&1.age, 2) == 0)
      |> Stream.map(& Map.put(&1, :age, &1.age + 1))
      |> Enum.to_list()
    end,
    "reduce+reverse: filter+map" => fn list ->
      Enum.reduce(list, [], fn user, result ->
        if rem(user.age, 2) == 0 do
          [Map.put(user, :age, user.age + 1) | result]
        else
          result
        end
      end)
      |> Enum.reverse()
    end,
    "reduce++: filter+map" => fn list ->
      Enum.reduce(list, [], fn user, result ->
        if rem(user.age, 2) == 0 do
          result ++ [Map.put(user, :age, user.age + 1)]
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
      "10" => Enum.slice(all_users, 0, 10),
      "100" => Enum.slice(all_users, 0, 100),
      "1_000" => Enum.slice(all_users, 0, 1_000),
      "10_000" => Enum.slice(all_users, 0, 10_000),
      "100_000" => Enum.slice(all_users, 0, 100_000),
      "1_000_000" => Enum.slice(all_users, 0, 1_000_000)
    }
)
