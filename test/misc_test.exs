defmodule CredoUnnecessaryReduce.MiscTest do
  use Credo.Test.Case, async: true

  alias CredoUnnecessaryReduce.Check

  # Don't really know that this would happen, TBH, because it means
  # you're doing a calculation that doesn't have any result, but good to check
  # that it doesn't return false positives here
  test "important part isn't the return value" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn i, acc ->
          intermediate = i / 3

          side_effect_fn(intermediate)

          acc ++ [intermediate * 2]

          acc
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn i, acc ->
          [i * 2 | acc]

          acc * 2
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn i, acc ->
          if rem(number, 2) == 0 do
            [number | result]
          else
            result
          end

          i * 5
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()
  end

  def assert_check_issue(code, message) do
    code
    |> assert_issue(fn issue ->
      assert issue.message == message
      assert issue.category == :refactor
    end)
  end
end
