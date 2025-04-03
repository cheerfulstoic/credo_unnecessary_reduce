defmodule CredoUnneccesaryReduce.ProductTest do
  use Credo.Test.Case, async: true

  alias CredoUnneccesaryReduce.Check

  describe "product" do
    test "Enum.product is good" do
      """
      defmodule NeoWeb.TestModule do
        def mult(numbers) do
          Enum.product(numbers)
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
          Enum.reduce(numbers, 1, fn number, result -> number * result end)
        end
      end
      """
      |> to_source_file("lib/neo_web/test_module.ex")
      |> run_check(Check)
      |> assert_check_issue("Consider using Enum.product instead of Enum.reduce.")

      """
      defmodule NeoWeb.TestModule do
        def mult(numbers) do
          Enum.reduce(numbers, 1, fn number, result -> result * number end)
        end
      end
      """
      |> to_source_file("lib/neo_web/test_module.ex")
      |> run_check(Check)
      |> assert_check_issue("Consider using Enum.product instead of Enum.reduce.")
    end

    test "ok to start with a different value or use different variables" do
      """
      defmodule NeoWeb.TestModule do
        def mult(numbers) do
          Enum.reduce(numbers, -1, fn i, acc -> i * acc end)
        end
      end
      """
      |> to_source_file("lib/neo_web/test_module.ex")
      |> run_check(Check)
      |> assert_check_issue("Consider using Enum.product instead of Enum.reduce.")

      """
      defmodule NeoWeb.TestModule do
        def mult(numbers) do
          Enum.reduce(numbers, 2, fn i, acc -> acc * i end)
        end
      end
      """
      |> to_source_file("lib/neo_web/test_module.ex")
      |> run_check(Check)
      |> assert_check_issue("Consider using Enum.product instead of Enum.reduce.")
    end
  end

  describe "product_by" do
    test "Enum.product_by is good" do
      """
      defmodule NeoWeb.TestModule do
        def mult(numbers) do
          Enum.product_by(numbers, fn number -> number * 2 end)
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
          Enum.reduce(numbers, 1, fn number, result -> (number + 2) * result end)
        end
      end
      """
      |> to_source_file("lib/neo_web/test_module.ex")
      |> run_check(Check)
      |> assert_check_issue("Consider using Enum.product_by instead of Enum.reduce.")

      """
      defmodule NeoWeb.TestModule do
        def mult(numbers) do
          Enum.reduce(numbers, 1, fn number, result -> result * (number + 2) end)
        end
      end
      """
      |> to_source_file("lib/neo_web/test_module.ex")
      |> run_check(Check)
      |> assert_check_issue("Consider using Enum.product_by instead of Enum.reduce.")

      """
      defmodule NeoWeb.TestModule do
        def mult(numbers) do
          Enum.reduce(numbers, 1.0, fn number, result -> (number + 2.2) * result end)
        end
      end
      """
      |> to_source_file("lib/neo_web/test_module.ex")
      |> run_check(Check)
      |> assert_check_issue("Consider using Enum.product_by instead of Enum.reduce.")

      """
      defmodule NeoWeb.TestModule do
        def mult(numbers) do
          Enum.reduce(numbers, 1.0, fn number, result -> result * (number + 2.2) end)
        end
      end
      """
      |> to_source_file("lib/neo_web/test_module.ex")
      |> run_check(Check)
      |> assert_check_issue("Consider using Enum.product_by instead of Enum.reduce.")
    end

    test "ok to start with a different value or use different variables" do
      """
      defmodule NeoWeb.TestModule do
        def mult(numbers) do
          Enum.reduce(numbers, -1, fn i, acc -> (i + 4) * acc end)
        end
      end
      """
      |> to_source_file("lib/neo_web/test_module.ex")
      |> run_check(Check)
      |> assert_check_issue("Consider using Enum.product_by instead of Enum.reduce.")

      """
      defmodule NeoWeb.TestModule do
        def mult(numbers) do
          Enum.reduce(numbers, 2, fn i, acc -> acc * (i + 4) end)
        end
      end
      """
      |> to_source_file("lib/neo_web/test_module.ex")
      |> run_check(Check)
      |> assert_check_issue("Consider using Enum.product_by instead of Enum.reduce.")
    end

    def assert_check_issue(code, message) do
      code
      |> assert_issue(fn issue ->
        assert issue.message == message
        assert issue.category == :refactor
      end)
    end
  end
end
