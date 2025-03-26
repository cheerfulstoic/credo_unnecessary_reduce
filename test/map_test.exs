defmodule CredoUnneccesaryReduce.MapTest do
  use Credo.Test.Case, async: true

  alias CredoUnneccesaryReduce.Check

  test "Enum.map is good" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.map(numbers, fn number -> number * 2 end)
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
        Enum.reduce(numbers, [], fn number, result -> [number * 2 | result] end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn i, acc -> [i * 10 | acc] end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  end

  test "other code in the function" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn number, result ->
          something = number * 2

          side_effect_fn(something)

          [something | result]
        end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn i, acc ->
          intermediate = i / 3

          side_effect_fn(intermediate)

          acc ++ [intermediate * 2]
        end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  end

  test "Doesn't matter if variable isn't used" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn _i, acc -> [:value | acc] end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  end

  test "Concatenation to the end" do
    # Don't know why anybody would do this, but covering this case in the tests...
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn _i, result -> result ++ [] end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn _i, result -> result ++ [:value] end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn _item, acc -> acc ++ [123] end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  end

  test "More complex examples" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, [], fn number, result -> [number * 2 | result] end)
        |> Enum.reverse()
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  end

  def assert_check_issue(code, message) do
    code
    |> assert_issue(fn issue ->
      assert issue.message == message
      assert issue.category == :refactor
    end)
  end
end
