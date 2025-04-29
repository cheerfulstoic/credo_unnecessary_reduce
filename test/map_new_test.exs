# Enum.reduce(has_permissions, %{}, fn {key, value}, acc ->
#   atom_key = permission_to_operation(key)
#   Map.put(acc, atom_key, value)
# end)

defmodule CredoUnnecessaryReduce.MapNewTest do
  use Credo.Test.Case, async: true

  alias CredoUnnecessaryReduce.Check

  test "Map.new is good" do
    """
    defmodule NeoWeb.TestModule do
      def doubles(numbers) do
        Map.new(numbers, & {&1, &1 * 2})
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
      def doubles(numbers) do
        Enum.reduce(numbers, %{}, fn number, acc ->
          Map.put(acc, number, number * 2)
        end)
      end
    end

    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Map.new instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def doubles(numbers) do
        Enum.reduce(numbers, %{}, fn number, acc ->
          double = number * 2
          Map.put(acc, number, double)
        end)
      end
    end

    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Map.new instead of Enum.reduce.")
  end

  test "ok when piped" do
    """
    defmodule NeoWeb.TestModule do
      def doubles(numbers) do
        numbers
        |> Enum.reduce(%{}, fn number, acc ->
          Map.put(acc, number, number * 2)
        end)
      end
    end

    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Map.new instead of Enum.reduce.")
  end

  test "Variables don't matter" do
    """
    defmodule NeoWeb.TestModule do
      def doubles(numbers) do
        Enum.reduce(numbers, %{}, fn i, result ->
          double = i * 2
          Map.put(result, i, double)
        end)
      end
    end

    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Map.new instead of Enum.reduce.")
  end

  test "From a map/keyword list" do
    """
    defmodule NeoWeb.TestModule do
      def doubles(keys_and_values) do
        Enum.reduce(keys_and_values, %{}, fn {key, i}, result ->
          double = i * 2
          Map.put(result, key, double)
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Map.new instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def doubles(keys_and_values) do
        Enum.reduce(new, %{}, fn %{key: key, value: value}, result ->
          double = value * 2
          Map.put(result, key, double)
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Map.new instead of Enum.reduce.")

    # This could be replaced with a Map.new + Map.merge, but for now
    # leaving this without a recommendation.
    """
    defmodule NeoWeb.TestModule do
      def doubles(new) do
        Enum.reduce(new, existing_fields, fn %{key: key, value: value}, acc ->
          Map.put(acc, key, value)
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()
  end

  # Enum.reduce(has_permissions, %{}, fn {key, value}, acc ->
  #   atom_key = permission_to_operation(key)
  #   Map.put(acc, atom_key, value)
  # end)

  def assert_check_issue(code, message) do
    code
    |> assert_issue(fn issue ->
      assert issue.message == message
      assert issue.category == :refactor
    end)
  end
end
