defmodule CredoUnnecessaryReduce.AllTest do
  use Credo.Test.Case, async: true

  alias CredoUnnecessaryReduce.Check

  test "Enum.all? is good" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.all?(numbers, fn number -> rem(number, 2) == 0 end)
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
        Enum.reduce(values, true, fn value, result ->
          result && value
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(values) do
        Enum.reduce(values, true, fn value, result ->
          value && result
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn number, result ->
          result && rem(number, 2) == 0
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn number, result ->
          rem(number, 2) == 0 && result
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn number, result ->
          result and rem(number, 2) == 0
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn number, result ->
          rem(number, 2) == 0 and result
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")
  end

  test "ok to use different variables" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn item, acc ->
          acc && rem(item, 2) == 0
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn item, acc ->
          rem(item, 2) == 0 && acc
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn item, acc ->
          acc and rem(item, 2) == 0
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn item, acc ->
          rem(item, 2) == 0 and acc
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")
  end

  test "ok when piped" do
    """
    defmodule NeoWeb.TestModule do
      def mult(values) do
        values
        |> Enum.reduce(true, fn value, result ->
          result && value
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")
  end

  test "More complex examples" do
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn item, acc ->
          rem(item, 2) == 0 && rem(item, 3) == 0 && acc
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")

    # This could maybe be detectable...
    # """
    # defmodule NeoWeb.TestModule do
    #   def mult(numbers) do
    #     Enum.reduce(numbers, true, fn item, acc ->
    #       acc && rem(item, 2) == 0 && rem(item, 3) == 0
    #     end)
    #   end
    # end
    # """
    # |> to_source_file("lib/neo_web/test_module.ex")
    # |> run_check(Check)
    # |> assert_check_issue("Consider using Enum.all? instead of Enum.reduce.")

    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn item, acc ->
          rem(item, 2) == 0 && rem(item, 3) == 0 || acc
        end)
      end
    end
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()

    # This should probably be convertable to all?
    # """
    # defmodule NeoWeb.TestModule do
    #   def mult(numbers) do
    #     Enum.reduce(numbers, true, fn item, acc ->
    #       rem(item, 2) == 0 || rem(item, 3) == 0 && acc
    #     end)
    #   end
    # end
    # """
    # |> to_source_file("lib/neo_web/test_module.ex")
    # |> run_check(Check)
    # |> refute_issues()

    # Worth checking?
    # """
    # defmodule NeoWeb.TestModule do
    #   def mult(numbers) do
    #     Enum.reduce(numbers, true, fn item, acc ->
    #       if rem(item, 2) == 0 do
    #         true
    #       else
    #         false
    #       end
    #     end)
    #   end
    # end
    # """
    # |> to_source_file("lib/neo_web/test_module.ex")
    # |> run_check(Check)
    # |> refute_issues()

    # Legitimately non-refactorable
    # ... or at least not worth checking 😅
    """
    defmodule NeoWeb.TestModule do
      def mult(numbers) do
        Enum.reduce(numbers, true, fn item, acc ->
          if rem(item, 2) == 0 do
            item || acc
          else
            rem(item, 2) == 0 || acc
          end
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
