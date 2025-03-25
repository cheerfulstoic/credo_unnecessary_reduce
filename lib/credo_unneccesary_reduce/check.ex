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
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Enum]}, :reduce]}, meta,
          [
            _enumerable,
            initial_value,
            {:fn, _, [{:->, _, [[{item_var, _, nil}, {acc_var, _, nil}], body_ast]}]}
          ]} =
           ast,
         issues,
         issue_meta
       ) do
    new_issue =
      if suggested_function = reduce_reducible_to(initial_value, item_var, acc_var, body_ast) do
        issue_for(
          issue_meta,
          meta[:line],
          "Consider using Enum.#{suggested_function} instead of Enum.reduce."
        )
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

  # Will this work?  Not sure if everything can be judged by the last line...
  defp reduce_reducible_to(
         initial_value,
         item_var,
         acc_var,
         {:__block__, _, list_ast}
       )
       when is_list(list_ast) do
    reduce_reducible_to(initial_value, item_var, acc_var, List.last(list_ast))
  end

  defp reduce_reducible_to(
         [],
         _item_var,
         acc_var,
         {:++, _, [{acc_var, _, nil}, list_ast]}
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

  defp reduce_reducible_to(
         [],
         _item_var,
         acc_var,
         list_ast
       )
       when is_list(list_ast) do
    if match?({:|, _, [_, {^acc_var, _, nil}]}, List.last(list_ast)) do
      case length(list_ast) do
        1 -> :map
        _ -> :flat_map
      end
    end
  end

  defp reduce_reducible_to(
         [],
         _item_var,
         acc_var,
         {:if, _, [_, [do: [{:|, _, [_, {acc_var, _, nil}]}], else: {acc_var, _, nil}]]}
       ) do
    :filter
  end

  defp reduce_reducible_to(
         [],
         _item_var,
         acc_var,
         {:if, _, [_, [do: {acc_var, _, nil}, else: [{:|, _, [_, {acc_var, _, nil}]}]]]}
       ) do
    :reject
  end

  defp reduce_reducible_to(
         [],
         _item_var,
         acc_var,
         {:if, _, [_, [do: {:++, _, [{acc_var, _, nil}, [_]]}, else: {acc_var, _, nil}]]}
       ) do
    :filter
  end

  defp reduce_reducible_to(
         [],
         _item_var,
         acc_var,
         {:if, _, [_, [do: {acc_var, _, nil}, else: {:++, _, [{acc_var, _, nil}, [_]]}]]}
       ) do
    :reject
  end

  defp reduce_reducible_to(
         init,
         item_var,
         acc_var,
         {operation, _, [part1_ast, part2_ast]}
       )
       when operation in ~w[+ - *]a do
    if is_ast_number?(init) do
      cond do
        match?({^acc_var, _, nil}, part1_ast) ->
          if match?({^item_var, _, _}, part2_ast) do
            if(operation == :*, do: :product, else: :sum)
          else
            if(operation == :*, do: :product_by, else: :sum_by)
          end

        match?({^acc_var, _, nil}, part2_ast) ->
          if match?({^item_var, _, _}, part1_ast) do
            if(operation == :*, do: :product, else: :sum)
          else
            if(operation == :*, do: :product_by, else: :sum_by)
          end
      end
    end
  end

  defp reduce_reducible_to(
         true,
         _item_var,
         acc_var,
         {operator, _,
          [
            {acc_var, _, nil},
            _
          ]}
       )
       when operator in [:&&, :and] do
    :all?
  end

  defp reduce_reducible_to(
         true,
         _item_var,
         acc_var,
         {operator, _,
          [
            _,
            {acc_var, _, nil}
          ]}
       )
       when operator in [:&&, :and] do
    :all?
  end

  defp reduce_reducible_to(
         false,
         _item_var,
         acc_var,
         {operator, _,
          [
            {acc_var, _, nil},
            _
          ]}
       )
       when operator in [:||, :or] do
    :any?
  end

  defp reduce_reducible_to(
         false,
         _item_var,
         acc_var,
         {operator, _,
          [
            _,
            {acc_var, _, nil}
          ]}
       )
       when operator in [:||, :or] do
    :any?
  end

  defp reduce_reducible_to(_init, _item_var, _acc_var, _ast) do
    nil
  end

  # defp reduce_reducible_to(init, item_var, acc_var, ast) do
  #   dbg()
  #   nil
  # end

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
