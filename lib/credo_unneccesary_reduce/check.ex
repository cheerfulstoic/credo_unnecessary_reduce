defmodule CredoUnneccesaryReduce.Check do
  @moduledoc """
  TODO
  """

  use Credo.Check,
    base_priority: :high,
    category: :refactor,
    # param_defaults: [include: ~r/lib\/.*_web\/controllers\/.*_controller\.ex/, exclude: ~r/fallback_controller\.ex/],
    explanations: [
      check: ~S"""
      TODO
      """
      # params: [exclude: "Pattern of which files to ignore", include: "Pattern of which files to validate."]
    ]

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    # |> Enum.reject(&is_nil/1)
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Enum]}, :reduce]}, meta, [_enumerable, initial_value, fun]} =
           ast,
         issues,
         issue_meta
       ) do
    new_issue =
      if suggested_function = reducible_to(initial_value, fun) do
        issue_for(
          issue_meta,
          meta[:line],
          "Consider using Enum.#{suggested_function} instead of Enum.reduce."
        )
      else
        # IO.puts("NO MATCH!")
        nil
      end

    if new_issue do
      {ast, [new_issue | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    # dbg(ast)
    {ast, issues}
  end

  defp reducible_to(
         [],
         {:fn, _,
          [{:->, _, [[{_, _, nil}, {acc_var, _, nil}], [{:|, _, [_, {acc_var, _, nil}]}]]}]}
       ) do
    :map
  end

  defp reducible_to(
         [],
         {:fn, _,
          [{:->, _, [[{_, _, nil}, {acc_var, _, nil}], {:++, _, [{acc_var, _, nil}, [_]]}]}]}
       ) do
    :map
  end

  defp reducible_to(
         [],
         {:fn, _,
          [
            {:->, _,
             [
               [_, {acc_var, _, nil}],
               {:if, _, [_, [do: [{:|, _, [_, {acc_var, _, nil}]}], else: {acc_var, _, nil}]]}
             ]}
          ]}
       ) do
    :filter
  end

  defp reducible_to(
         [],
         {:fn, _,
          [
            {:->, _,
             [
               [_, {acc_var, _, nil}],
               {:if, _, [_, [do: {acc_var, _, nil}, else: [{:|, _, [_, {acc_var, _, nil}]}]]]}
             ]}
          ]}
       ) do
    :filter
  end

  defp reducible_to(
         [],
         {:fn, _,
          [
            {:->, _,
             [
               [_, {acc_var, _, nil}],
               {:if, _, [_, [do: {:++, _, [{acc_var, _, nil}, [_]]}, else: {acc_var, _, nil}]]}
             ]}
          ]}
       ) do
    :filter
  end

  defp reducible_to(
         [],
         {:fn, _,
          [
            {:->, _,
             [
               [_, {acc_var, _, nil}],
               {:if, _, [_, [do: {acc_var, _, nil}, else: {:++, _, [{acc_var, _, nil}, [_]]}]]}
             ]}
          ]}
       ) do
    :filter
  end

  defp reducible_to(_, _), do: nil

  defp issue_for(issue_meta, line_no, message) do
    format_issue(
      issue_meta,
      message: message,
      line_no: line_no
    )
  end
end
