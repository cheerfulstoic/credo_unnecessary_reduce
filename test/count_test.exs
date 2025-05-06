defmodule CredoUnnecessaryReduce.CountTest do
  use Credo.Test.Case, async: true

  alias CredoUnnecessaryReduce.Check

  test "Enum.count is good" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.count(numbers)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.count(numbers, fn number -> rem(number, 2) == 0 end)
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
        Enum.reduce(numbers, 0, fn _, result -> result + 1 end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")

    # Using a number other than one can be solved by `Enum.count` * <number>
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, 0, fn _, result -> result + 3 end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, 0, fn _, result -> 1 + result end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")

    # Using a number other than one can be solved by `Enum.count` * <number>
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, 0, fn _, result -> 3 + result end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, 0, fn number, result ->
          if rem(number, 2) == 0 do
            result + 1
          else
            result
          end
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, 0, fn number, result ->
          if rem(number, 2) == 1 do
            result
          else
            result + 1
          end
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, 0, fn number, result ->
          if rem(number, 2) == 0 do
            1 + result
          else
            result
          end
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, 0, fn number, result ->
          if rem(number, 2) == 1 do
            result
          else
            1 + result
          end
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")
  end

  test "catches when Enum.reduce is piped" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        numbers
        |> Enum.reduce(0, fn _, result -> result + 1 end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")
  end

  # test "other code in the function" do
  #   """
  #   defmodule NeoWeb.TestModule do
  #     def mult(numbers) do
  #       Enum.reduce(numbers, [], fn number, result ->
  #         something = number * 2
  #
  #         side_effect_fn(something)
  #
  #         [something | result]
  #       end)
  #       |> Enum.reverse()
  #     end
  #   end
  #   """
  #   |> to_source_file("lib/neo_web/test_module.ex")
  #   |> run_check(Check)
  #   |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  #
  #   """
  #   defmodule NeoWeb.TestModule do
  #     def mult(numbers) do
  #       Enum.reduce(numbers, [], fn i, acc ->
  #         intermediate = i / 3
  #
  #         side_effect_fn(intermediate)
  #
  #         acc ++ [intermediate * 2]
  #       end)
  #       |> Enum.reverse()
  #     end
  #   end
  #   """
  #   |> to_source_file("lib/neo_web/test_module.ex")
  #   |> run_check(Check)
  #   |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  # end
  #
  #
  #

  test "Doesn't matter if different variable or different initial value is used" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, 2, fn _, acc -> acc + 1 end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, -2, fn _, count -> 1 + count end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, 0, fn number, acc ->
          if rem(number, 2) == 0 do
            acc + 1
          else
            acc
          end
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, 0, fn number, count ->
          if rem(number, 2) == 1 do
            count
          else
            count + 1
          end
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.count instead of Enum.reduce.")
  end

  # test "Doesn't matter if variable isn't used" do
  #   """
  #   defmodule NeoWeb.TestModule do
  #     def mult(numbers) do
  #       Enum.reduce(numbers, [], fn _i, acc -> [:value | acc] end)
  #       |> Enum.reverse()
  #     end
  #   end
  #   """
  #   |> to_source_file("lib/neo_web/test_module.ex")
  #   |> run_check(Check)
  #   |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  # end
  #
  # test "Concatenation to the end" do
  #   # Don't know why anybody would do this, but covering this case in the tests...
  #   """
  #   defmodule NeoWeb.TestModule do
  #     def mult(numbers) do
  #       Enum.reduce(numbers, [], fn _i, result -> result ++ [] end)
  #     end
  #   end
  #   """
  #   |> to_source_file("lib/neo_web/test_module.ex")
  #   |> run_check(Check)
  #   |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  #
  #   """
  #   defmodule NeoWeb.TestModule do
  #     def mult(numbers) do
  #       Enum.reduce(numbers, [], fn _i, result -> result ++ [:value] end)
  #     end
  #   end
  #   """
  #   |> to_source_file("lib/neo_web/test_module.ex")
  #   |> run_check(Check)
  #   |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  #
  #   """
  #   defmodule NeoWeb.TestModule do
  #     def mult(numbers) do
  #       Enum.reduce(numbers, [], fn _item, acc -> acc ++ [123] end)
  #     end
  #   end
  #   """
  #   |> to_source_file("lib/neo_web/test_module.ex")
  #   |> run_check(Check)
  #   |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  # end
  #
  # test "More complex examples" do
  #   """
  #   defmodule NeoWeb.TestModule do
  #     def mult(numbers) do
  #       Enum.reduce(numbers, [], fn number, result -> [number * 2 | result] end)
  #       |> Enum.reverse()
  #     end
  #   end
  #   """
  #   |> to_source_file("lib/neo_web/test_module.ex")
  #   |> run_check(Check)
  #   |> assert_check_issue("Consider using Enum.map instead of Enum.reduce.")
  # end

  def assert_check_issue(code, message) do
    code
    |> assert_issue(fn issue ->
      assert issue.message == message
      assert issue.category == :refactor
    end)
  end
end
