defmodule CredoUnneccesaryReduce.AnyTest do
  use Credo.Test.Case, async: true

  alias CredoUnneccesaryReduce.Check

  test "Enum.any? is good" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.any?(numbers, fn number -> rem(number, 2) == 0 end)
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
      def mult(values) do
        Enum.reduce(values, false, fn value, result ->
          result || value
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(values) do
        Enum.reduce(values, false, fn value, result ->
          value || result
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, false, fn number, result ->
          result || rem(number, 2) == 0
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, false, fn number, result ->
          rem(number, 2) == 0 || result
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, false, fn number, result ->
          result or rem(number, 2) == 0
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, false, fn number, result ->
          rem(number, 2) == 0 or result
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")
  end

  test "ok to use different variables" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, false, fn item, acc ->
          acc || rem(item, 2) == 0
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, false, fn item, acc ->
          rem(item, 2) == 0 || acc
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, false, fn item, acc ->
          acc or rem(item, 2) == 0
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, false, fn item, acc ->
          rem(item, 2) == 0 or acc
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")
  end

  test "More complex examples" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, false, fn item, acc ->
          rem(item, 2) == 0 || rem(item, 3) == 0 || acc
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.any? instead of Enum.reduce.")
  end

  def assert_check_issue(code, message) do
    code
    |> assert_issue(fn issue ->
      assert issue.message == message
      assert issue.category == :refactor
    end)
  end
end
