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

  # {:-, [line: 3, column: 26], [1]}

  defguard is_ast_number(term) when is_integer(term) and rem(term, 2) == 0
  defguard is_ast_number(term) when is_integer(term) and rem(term, 2) == 0

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
          [{:->, _, [[{_, _, nil}, {acc_var, _, nil}], {:++, _, [{acc_var, _, nil}, list_ast]}]}]}
       )
       when is_list(list_ast) do
    case length(list_ast) do
      0 ->
        :map

      1 ->
        :map

      _ ->
        :flat_map
    end
  end

  defp reducible_to(
         [],
         {
           :fn,
           _,
           [{:->, _, [[{_, _, nil}, {acc_var, _, nil}], list_ast]}]
         }
       )
       when is_list(list_ast) do
    if match?({:|, _, [_, {^acc_var, _, nil}]}, List.last(list_ast)) do
      case length(list_ast) do
        1 -> :map
        _ -> :flat_map
      end
    end
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

  defp reducible_to(
         init,
         {:fn, _,
          [
            {:->, _,
             [
               [{item_var, _, nil}, {acc_var, _, nil}],
               {:+, _,
                [
                  other_part_ast,
                  {acc_var, _, nil}
                ]}
             ]}
          ]}
       ) do
    if is_ast_number?(init) do
      if match?({^item_var, _, _}, other_part_ast) do
        :sum
      else
        :sum_by
      end
    end
  end

  defp reducible_to(
         init,
         {:fn, _,
          [
            {:->, _,
             [
               [{item_var, _, nil}, {acc_var, _, nil}],
               {:+, _,
                [
                  {acc_var, _, nil},
                  other_part_ast
                ]}
             ]}
          ]}
       ) do
    if is_ast_number?(init) do
      if match?({^item_var, _, _}, other_part_ast) do
        :sum
      else
        :sum_by
      end
    end
  end

  defp reducible_to(
         true,
         {:fn, _,
          [
            {:->, _,
             [
               [_, {acc_var, _, nil}],
               {operator, _,
                [
                  {acc_var, _, nil},
                  _
                ]}
             ]}
          ]}
       )
       when operator in [:&&, :and] do
    :all?
  end

  defp reducible_to(
         true,
         {:fn, _,
          [
            {:->, _,
             [
               [_, {acc_var, _, nil}],
               {operator, _,
                [
                  _,
                  {acc_var, _, nil}
                ]}
             ]}
          ]}
       )
       when operator in [:&&, :and] do
    :all?
  end

  defp reducible_to(
         false,
         {:fn, _,
          [
            {:->, _,
             [
               [_, {acc_var, _, nil}],
               {operator, _,
                [
                  {acc_var, _, nil},
                  _
                ]}
             ]}
          ]}
       )
       when operator in [:||, :or] do
    :any?
  end

  defp reducible_to(
         false,
         {:fn, _,
          [
            {:->, _,
             [
               [_, {acc_var, _, nil}],
               {operator, _,
                [
                  _,
                  {acc_var, _, nil}
                ]}
             ]}
          ]}
       )
       when operator in [:||, :or] do
    :any?
  end

  defp reducible_to(init, ast) do
    # dbg()
    nil
  end

  # If this could be a guard, so much the better
  defp is_ast_number?(number) when is_integer(number) or is_float(number), do: true
  defp is_ast_number?({:-, _, [number]}) when is_integer(number) or is_float(number), do: true
  defp is_ast_number?(_), do: false

  defp issue_for(issue_meta, line_no, message) do
    format_issue(
      issue_meta,
      message: message,
      line_no: line_no
    )
  end
end
