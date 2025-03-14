defmodule CredoUnneccesaryReduce.FilterTest do
  use Credo.Test.Case, async: true

  alias CredoUnneccesaryReduce.Check

  test "Enum.filter is good" do
    """
    defmodule NeoWeb.TestModule do
      def only_even(numbers) do
        Enum.filter(numbers, fn number -> rem(number, 2) == 0 end)
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
      def only_even(numbers) do
        Enum.reduce(numbers, [], fn number, result ->
          if rem(number, 2) == 0 do
            [number | result]
          else
            result
          end
        end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.filter instead of Enum.reduce.")

    # Flip the order
    """
    defmodule NeoWeb.TestModule do
      def only_even(numbers) do
        Enum.reduce(numbers, [], fn number, result ->
          if rem(number, 2) != 0 do
            result
          else
            [number | result]
          end
        end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.reject instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def only_even(numbers) do
        Enum.reduce(numbers, [], fn item, acc ->
          if rem(item, 2) == 0 do
            [item | acc]
          else
            acc
          end
        end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.filter instead of Enum.reduce.")
  end

  test "Concatenation to the end" do
    """
    defmodule NeoWeb.TestModule do
      def only_even(numbers) do
        Enum.reduce(numbers, [], fn number, result ->
          if rem(number, 2) == 0 do
            result ++ [number]
          else
            result
          end
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.filter instead of Enum.reduce.")

    # Flip the order
    """
    defmodule NeoWeb.TestModule do
      def only_even(numbers) do
        Enum.reduce(numbers, [], fn number, result ->
          if rem(number, 2) != 0 do
            result
          else
            result ++ [number]
          end
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.reject instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def only_even(numbers) do
        Enum.reduce(numbers, [], fn item, acc ->
          if rem(item, 2) == 0 do
            acc ++ [item]
          else
            acc
          end
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.filter instead of Enum.reduce.")
  end

  def assert_check_issue(code, message) do
    code
    |> assert_issue(fn issue ->
      assert issue.message == message
      assert issue.category == :refactor
    end)
  end
end
