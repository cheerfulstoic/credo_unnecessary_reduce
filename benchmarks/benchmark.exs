defmodule Benchee.Formatters.CSV do
  @moduledoc """
  Functionality for converting Benchee benchmarking results to CSV so that
  they can be written to file and opened in a spreadsheet tool for graph
  generation for instance.

  The most basic use case is to configure it as one of the formatters to be
  used by `Benchee.run/2`.

      Benchee.run(
        %{
          "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
          "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
        },
        formatters: [
          {Benchee.Formatters.CSV, file: "my.csv"},
          Benchee.Formatters.Console
        ]
      )

  """
  @behaviour Benchee.Formatter

  alias Benchee.Formatters.CSV.{Raw, Statistics, Util}
  alias Benchee.Suite
  alias Benchee.Utility.FileCreation

  @doc """
  Transforms the statistical results `Benche.statistics` to be written
  somewhere, such as a file through `IO.write/2`.

  ## Examples

      iex> suite = %Benchee.Suite{
      ...> 	scenarios: [
      ...> 		%Benchee.Scenario{
      ...> 			name: "My Job",
      ...> 			input_name: "Some Input",
      ...> 			input: "Some Input",
      ...> 			run_time_data: %Benchee.CollectionData{
      ...>        samples: [500],
      ...>        statistics: %Benchee.Statistics{
      ...> 				  average:       500.0,
      ...> 				  ips:           2000.0,
      ...> 				  std_dev:       200.0,
      ...> 				  std_dev_ratio: 0.4,
      ...> 				  std_dev_ips:   800.0,
      ...> 				  median:        450.0,
      ...> 				  minimum:       200,
      ...> 				  maximum:       900,
      ...> 				  sample_size:   8
      ...>        }
      ...> 			},
      ...> 			memory_usage_data: %Benchee.CollectionData{
      ...>        samples: [500],
      ...>        statistics: %Benchee.Statistics{
      ...> 				  average:       500.0,
      ...> 				  ips:           nil,
      ...> 				  std_dev:       200.0,
      ...> 				  std_dev_ratio: 0.4,
      ...> 				  std_dev_ips:   nil,
      ...> 				  median:        450.0,
      ...> 				  minimum:       200,
      ...> 				  maximum:       900,
      ...> 				  sample_size:   8
      ...>        }
      ...> 			}
      ...> 		}
      ...> 	]
      ...> }
      iex> suite
      iex> |> Benchee.Formatters.CSV.format(%{})
      iex> |> elem(0)
      iex> |> (fn rows -> Enum.take(rows, 2) end).()
      [
        "Name,Input,Iterations per Second,Standard Deviation Iterations Per Second,Run Time Average,Run Time Median,Run Time Minimum,Run Time Maximum,Run Time Standard Deviation,Run Time Standard Deviation Ratio,Run Time Sample Size,Memory Usage Average,Memory Usage Median,Memory Usage Minimum,Memory Usage Maximum,Memory Usage Standard Deviation,Memory Usage Standard Deviation Ratio,Memory Usage Sample Size\\r\\n",
        "My Job,Some Input,2.0e3,800.0,500.0,450.0,200,900,200.0,0.4,8,500.0,450.0,200,900,200.0,0.4,8\\r\\n"
      ]
  """
  @spec format(Suite.t(), any) :: {Enumerable.t(), Enumerable.t()}
  def format(%Suite{scenarios: scenarios}, _) do
    sorted_scenarios = Enum.sort_by(scenarios, fn scenario -> scenario.input_name end)

    # {get_benchmarks_statistics(sorted_scenarios), get_benchmarks_raw(sorted_scenarios)}
    get_benchmarks_statistics(sorted_scenarios)
  end

  defp get_benchmarks_statistics(scenarios) do
    scenarios
    |> Enum.map(&Statistics.to_csv/1)
    |> Statistics.add_headers()
    |> CSV.encode()
  end

  # defp get_benchmarks_raw(scenarios) do
  #   scenarios
  #   |> Enum.flat_map(&Raw.to_csv/1)
  #   |> Util.zip_all()
  #   |> Raw.add_headers(scenarios)
  #   |> CSV.encode()
  # end

  @doc """
  Uses the return value of `Benchee.Formatters.CSV.format/2` to write the
  statistics output to a CSV file, defined in the initial
  configuration. The raw measurements are placed in a file with "raw_" prepended
  onto the file name given in the initial configuration.

  If no file name is given in the configuration, "benchmark_output.csv" is used
  as a default.
  """
  @spec write({Enumerable.t(), Enumerable.t()}, map | nil) :: :ok
  # def write({statistics, raw_measurements}, options) do
  def write(statistics, options) do
    filename = Map.get(options, :file, "benchmark_output.csv")
    write_file(statistics, filename, "statistics")
    # write(raw_measurements, FileCreation.interleave(filename, "raw"), "raw measurements")
  end

  defp write_file(content, filename, type) do
    File.open(filename, [:write, :utf8], fn file ->
      Enum.each(content, fn row -> IO.write(file, row) end)
    end)

    IO.puts("#{type} CSV written to #{filename}")
  end
end



all_users =
  Enum.map(1..1_000_000, fn i ->
    %{name: "User #{i}", age: i}
  end)
  # |> Enum.take_random(1_000_000)

defprotocol EnumActions do
  def map(value)
  def filter(value)
  def any_check(value, count)
end

defimpl EnumActions, for: Integer do
  use Bitwise

  def map(i), do: i * i
  def filter(i), do: rem(i, 2) == 0
  def any_check(i, count), do: i >= (count >>> 1)
end

defimpl EnumActions, for: Map do
  use Bitwise

  def map(map), do: Map.put(map, :age, map.age + 1)
  def filter(map), do: rem(map.age, 2) == 0
  def any_check(map, count), do: map.age >= (count >>> 1)
end

inputs =
  [10, 100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000]
  |> Enum.reduce(%{}, fn i, result ->
    i_inputs =
      if i <= 1_000_000 do
        %{
          "#{i} integers" => {i, 1..i},
          "#{i} maps" => {i, Enum.slice(all_users, 0, i)}
        }
      else
        %{
          "#{i} integers" => {i, 1..i}
        }
      end
    Map.merge(result, i_inputs)
  end)

# NOTE: Previously this included cases where `++` was used instead of a reduce of `[_ | result]` + Enum.reverse,
# but it was always way slower, so it's just not included in the tests.

Benchee.run(
  %{
    "enum|map" => fn {count, list} ->
      Enum.map(list, & EnumActions.map/1)
    end,
    "stream|map" => fn {count, list} ->
      Stream.map(list, &EnumActions.map/1)
      # |> Enum.to_list()
      |> Stream.run()
    end,
    "reduce+reverse|map" => fn {count, list} ->
      Enum.reduce(list, [], fn i, result ->
        [EnumActions.map(i) | result]
      end)
      |> Enum.reverse()
    end,

    "enum|any?" => fn {count, list} ->
      Enum.any?(list, & EnumActions.any_check(&1, count))
    end,
    # There is no Stream.any?
    # "stream|any?" => fn list ->
    #   Stream.any?(list, & EnumActions.any_check(&1, count))
    # end,
    "reduce|any?" => fn {count, list} ->
      Enum.reduce(list, false, fn i, result ->
        result || EnumActions.any_check(i, count)
      end)
    end,
    "reduce_while|any?" => fn {count, list} ->
      Enum.reduce_while(list, false, fn i, _result ->
        if EnumActions.any_check(i, count) do
          {:halt, true}
        else
          {:cont, false}
        end
      end)
    end,

    "enum|filter+map" => fn {count, list} ->
      list
      |> Enum.filter(&EnumActions.filter/1)
      |> Enum.map(&EnumActions.map/1)
    end,
    "stream|filter+map" => fn {count, list} ->
      list
      |> Stream.filter(&EnumActions.filter/1)
      |> Stream.map(&EnumActions.map/1)
      # |> Enum.to_list()
      |> Stream.run()
    end,
    "reduce+reverse|filter+map" => fn {count, list} ->
      Enum.reduce(list, [], fn i, result ->
        if EnumActions.filter(i) do
          [EnumActions.map(i) | result]
        else
          result
        end
      end)
      |> Enum.reverse()
    end,

    "enum|filter+map+any?" => fn {count, list} ->
      list
      |> Enum.filter(&EnumActions.filter/1)
      |> Enum.map(&EnumActions.map/1)
      |> Enum.any?(& EnumActions.any_check(&1, count))
    end,
    "stream|filter+map+any?" => fn {count, list} ->
      list
      |> Stream.filter(&EnumActions.filter/1)
      |> Stream.map(&EnumActions.map/1)
      |> Enum.any?(& EnumActions.any_check(&1, count))
    end,
    "reduce|filter+map+any?" => fn {count, list} ->
      Enum.reduce(list, false, fn i, result ->
        if EnumActions.filter(i) do
          result || EnumActions.any_check(EnumActions.map(i), count)
        else
          result
        end
      end)
    end,
    "reduce_while|filter+map+any?" => fn {count, list} ->
      Enum.reduce_while(list, false, fn i, _result ->
        if EnumActions.filter(i) do
          if EnumActions.any_check(EnumActions.map(i), count) do
            {:halt, true}
          else
            {:cont, false}
          end
        else
          {:cont, false}
        end
      end)
    end,
  },
  warmup: 0.5,
  time: 5,
  inputs: inputs,
  formatters: [
    # {Benchee.Formatters.HTML, file: "benchmarks/benchmark/result.html"},
    {Benchee.Formatters.CSV, file: "benchmarks/benchmark.csv"},
    Benchee.Formatters.Console
  ]

)

