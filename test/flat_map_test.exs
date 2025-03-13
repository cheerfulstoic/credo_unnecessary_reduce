defmodule CredoUnneccesaryReduce.FlatMapTest do
  use Credo.Test.Case, async: true

  alias CredoUnneccesaryReduce.Check

  test "Enum.flat_map is good" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.flat_map(numbers, fn number -> [number * 2, number * 4] end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()
  end

  test "Enum.reduce, oh no!" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn number, result -> [number * 4, number * 2 | result] end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.flat_map instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn number, result -> [number * 8, number * 4, number * 2 | result] end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.flat_map instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn i, acc -> [i * 8, i * 4 | acc] end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.flat_map instead of Enum.reduce.")
  end

  test "Doesn't matter if variable isn't used" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn _i, acc -> [:value1, :value2 | acc] end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.flat_map instead of Enum.reduce.")
  end

  test "Concatenation to the end" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn number, result -> result ++ [number * 4, number * 2] end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.flat_map instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn _i, result -> result ++ [:value1, :value2] end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.flat_map instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn _item, acc -> acc ++ [123, 456] end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.flat_map")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.flat_map instead of Enum.reduce.")
  end

  def assert_check_issue(code, message) do
    code
    |> assert_issue(fn issue ->
      assert issue.message == message
      assert issue.category == :refactor
    end)
  end
end
