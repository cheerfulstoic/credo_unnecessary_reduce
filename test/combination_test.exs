defmodule CredoUnneccesaryReduce.CombinationTest do
  use Credo.Test.Case, async: true

  alias CredoUnneccesaryReduce.Check

  test "Something that can be simplified to Enum.filter + Enum.map" do
    """
    defmodule NeoWeb.TestModule do
      def only_even(numbers) do
        Enum.reduce(numbers, [], fn item, acc ->
          if rem(item, 2) == 0 do
            acc ++ [item * 2]
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

    """
    defmodule NeoWeb.TestModule do
      def only_even(numbers) do
        Enum.reduce(numbers, [], fn item, acc ->
          if rem(item, 2) == 0 do
            [item * 2 | acc]
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

  def assert_check_issue(code, message) do
    code
    |> assert_issue(fn issue ->
      assert issue.message == message
      assert issue.category == :refactor
    end)
  end
end
