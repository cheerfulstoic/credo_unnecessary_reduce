defmodule CredoUnnecessaryReduce.SplitWithTest do
  use Credo.Test.Case, async: true

  alias CredoUnnecessaryReduce.Check

  test "Enum.split_with is good" do
    """
    {events, odds} =
      Enum.split_with(numbers, & rem(number, 2) == 0)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()
  end

  test "Enum.reduce, oh no!" do
    """
    {events, odds} =
      Enum.reduce(numbers, {[], []}, fn number, {evens, odds} ->
        if rem(number, 2) == 0 do
          {[number | evens], odds}
        else
          {evens, [number | odds]}
        end
      end)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.split_with instead of Enum.reduce.")

    """
    {events, odds} =
      Enum.reduce(numbers, {[], []}, fn number, {evens, odds} ->
        if rem(number, 2) == 0 do
          {odds, [number | evens]}
        else
          {[number | odds], evens}
        end
      end)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.split_with instead of Enum.reduce.")

    # These last ones are weird examples, but we want to make sure we only capture the
    # relatively straightforward cases
    """
    {events, odds} =
      Enum.reduce(numbers, {[], []}, fn number, {evens, odds} ->
        if rem(number, 2) == 0 do
          {[number | odds], [number | evens]}
        else
          {[number | odds], evens}
        end
      end)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()

    """
    {events, odds} =
      Enum.reduce(numbers, {[], []}, fn number, {evens, odds} ->
        if rem(number, 2) == 0 do
          {odds, [number | evens]}
        else
          {odds, evens}
        end
      end)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()

    """
    {events, odds} =
      Enum.reduce(numbers, {[], []}, fn number, {evens, odds} ->
        if rem(number, 2) == 0 do
          {odds, evens}
        else
          {odds, evens}
        end
      end)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> refute_issues()
  end

  test "catches when Enum.reduce is piped" do
    """
    {events, odds} =
      numbers
      |> Enum.reduce({[], []}, fn number, {evens, odds} ->
        if rem(number, 2) == 0 do
          {[number | evens], odds}
        else
          {evens, [number | odds]}
        end
      end)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.split_with instead of Enum.reduce.")
  end

  test "other code in the function" do
    """
    {events, odds} =
      Enum.reduce(numbers, {[], []}, fn number, {evens, odds} ->
        even? = rem(number, 2) == 0

        if even? do
          {[number | evens], odds}
        else
          {evens, [number | odds]}
        end
      end)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.split_with instead of Enum.reduce.")
  end

  test "Doesn't matter if variable isn't used" do
    """
    {events, odds} =
      Enum.reduce(numbers, {[], []}, fn number, {evens, odds} ->
        if rem(number, 2) == 0 do
          {[:even | evens], odds}
        else
          {evens, [:odd | odds]}
        end
      end)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.split_with instead of Enum.reduce.")
  end

  test "Concatenation to the end" do
    """
    {events, odds} =
      Enum.reduce(numbers, {[], []}, fn number, {evens, odds} ->
        if rem(number, 2) == 0 do
          {evens ++ [number], odds}
        else
          {evens, odds ++ [number]}
        end
      end)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.split_with instead of Enum.reduce.")
  end

  test "More complex examples" do
    """
    {available, discarded} =
      Enum.reduce(jobs, {[], []}, fn job, {res_acc, dis_acc} ->
        if job.attempt < job.max_attempts do
          {[Map.put(job, :state, "available") | res_acc], dis_acc}
        else
          {res_acc, [Map.put(job, :state, "discarded") | dis_acc]}
        end
      end)
    """
    |> to_source_file("lib/neo_web/test_module.ex")
    |> run_check(Check)
    |> assert_check_issue("Consider using Enum.split_with instead of Enum.reduce.")

    """
    {available, discarded} =
      Enum.map(jobs, fn job ->
        new_state = if(job.attempt < job.max_attempts, do: "available", else: "discarded")

        Map.put(job, :state, new_state)
      end)
      |> Enum.split_with(&(&1.state == "available"))
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
