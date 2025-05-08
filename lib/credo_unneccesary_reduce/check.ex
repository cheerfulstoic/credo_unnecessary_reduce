defmodule CredoUnnecessaryReduce.Check do
  @moduledoc """
  This Credo check identifies instances where `Enum.reduce` can be 
  replaced with more idiomatic and efficient functions, such as 
  `Enum.filter`, `Enum.map`, `Enum.any?`, and `Map.new`.

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

  # For when the function is called directly
  defp traverse(
         {{:., _, [{:__aliases__, _, [:Enum]}, :reduce]} = call_ast, meta,
          [
            _enumerable,
            initial_value,
            {:fn, _, [{:->, _, [[_item_ast, _acc_ast], _body_ast]}]} = fn_ast
          ]},
         issues,
         issue_meta
       ) do
    traverse(
      {call_ast, meta, [initial_value, fn_ast]},
      issues,
      issue_meta
    )
  end

  # For when the function is piped
  defp traverse(
         {{:., _, [{:__aliases__, _, [:Enum]}, :reduce]}, meta,
          [
            initial_value,
            {:fn, _, [{:->, _, [[item_ast, acc_ast], body_ast]}]}
          ]} =
           ast,
         issues,
         issue_meta
       ) do
    # Not ideal really, but these might be the only cases we deal with
    # and it would be nice to avoid having `reduce_reducible_to` have to
    # deal with more ast stuff...
    new_issue =
      case reduce_reducible_to(initial_value, item_ast, acc_ast, body_ast) do
        suggested_functions when is_list(suggested_functions) ->
          suggestions = Enum.join(suggested_functions, " or ")

          issue_for(
            issue_meta,
            meta[:line],
            "Consider using #{suggestions} instead of Enum.reduce."
          )

        nil ->
          nil

        suggested_function ->
          issue_for(
            issue_meta,
            meta[:line],
            "Consider using #{suggested_function} instead of Enum.reduce."
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
         item_ast,
         acc_ast,
         {:__block__, _, list_ast}
       )
       when is_list(list_ast) do
    reduce_reducible_to(initial_value, item_ast, acc_ast, List.last(list_ast))
  end

  defp reduce_reducible_to(
         [],
         _item_ast,
         {acc_var, _, nil},
         {:++, _, [{acc_var, _, nil}, list_ast]}
       )
       when is_list(list_ast) do
    case length(list_ast) do
      0 ->
        "Enum.map"

      1 ->
        "Enum.map"

      _ ->
        "Enum.flat_map"
    end
  end

  defp reduce_reducible_to(
         [],
         _item_ast,
         {acc_var, _, nil},
         list_ast
       )
       when is_list(list_ast) do
    if match?({:|, _, [_, {^acc_var, _, nil}]}, List.last(list_ast)) do
      case length(list_ast) do
        1 -> "Enum.map"
        _ -> "Enum.flat_map"
      end
    end
  end

  defp reduce_reducible_to(
         initial_value,
         item_ast,
         {acc_var, _, nil},
         {:if, _, [_, [do: ast, else: {acc_var, _, nil}]]}
       ) do
    if_is_reducible_to(initial_value, item_ast, acc_var, ast)
  end

  defp reduce_reducible_to(
         initial_value,
         item_ast,
         {acc_var, _, nil},
         {:if, _, [_, [do: {acc_var, _, nil}, else: ast]]}
       ) do
    if_is_reducible_to(initial_value, item_ast, acc_var, ast)
  end

  defp reduce_reducible_to(
         init,
         {item_var, _, nil},
         {acc_var, _, nil},
         {operation, _, [part1_ast, part2_ast]}
       )
       when operation in ~w[+ - *]a do
    # Doing some sort of mathimatical reduction
    # TODO: Deal with floats!
    if is_ast_number?(init) do
      [type1, type2] =
        [part1_ast, part2_ast]
        |> Enum.map(fn
          {^acc_var, _, nil} -> :acc_var
          {^item_var, _, nil} -> :item_var
          part when is_integer(part) -> :integer
          _ -> :other
        end)
        |> Enum.sort()

      # Both :+ and :- have the same recommendation
      # Subtraction could be considered addition of negative numbers
      operation_type = if(operation == :*, do: :mult, else: :addition)

      case {type1, type2, operation_type} do
        {:acc_var, :item_var, :mult} -> "Enum.product"
        {:acc_var, :item_var, :addition} -> "Enum.sum"
        {:acc_var, :integer, :mult} -> nil
        {:acc_var, :integer, :addition} -> "Enum.count"
        {:acc_var, _, :mult} -> "Enum.product_by"
        {:acc_var, _, :addition} -> "Enum.sum_by"
      end
    end
  end

  defp reduce_reducible_to(
         true,
         _item_ast,
         {acc_var, _, nil},
         {operator, _,
          [
            {acc_var, _, nil},
            _
          ]}
       )
       when operator in [:&&, :and] do
    "Enum.all?"
  end

  defp reduce_reducible_to(
         true,
         _item_ast,
         {acc_var, _, nil},
         {operator, _,
          [
            _,
            {acc_var, _, nil}
          ]}
       )
       when operator in [:&&, :and] do
    "Enum.all?"
  end

  defp reduce_reducible_to(
         false,
         _item_ast,
         {acc_var, _, nil},
         {operator, _,
          [
            {acc_var, _, nil},
            _
          ]}
       )
       when operator in [:||, :or] do
    "Enum.any?"
  end

  defp reduce_reducible_to(
         false,
         _item_ast,
         {acc_var, _, nil},
         {operator, _,
          [
            _,
            {acc_var, _, nil}
          ]}
       )
       when operator in [:||, :or] do
    "Enum.any?"
  end

  defp reduce_reducible_to(
         {:%{}, _, _},
         _item_ast,
         {acc_var, _, nil},
         {{:., _, [{:__aliases__, _, [:Map]}, :put]}, _,
          [
            {acc_var, _, nil},
            _,
            _
          ]}
       ) do
    "Map.new"
  end

  defp reduce_reducible_to(
         {[], []},
         {_item_var, _, nil},
         {{_true_ast_var, _, nil}, {_false_ast_var, _, nil}},
         {:if, _,
          [
            _,
            [
              do: {
                do_ast1,
                do_ast2
              },
              else: {
                else_ast1,
                else_ast2
              }
            ]
          ]}
       ) do
    adds_item_fn = fn ast ->
      match?(
        [
          {:|, _,
           [
             _,
             {_true_ast_var, _, nil}
           ]}
        ],
        ast
      ) ||
        match?({:++, _, [{_true_ast_var, _, nil}, [_]]}, ast)
    end

    keeps_same_fn = fn
      {var, _, nil} when is_atom(var) -> true
      _ -> false
    end

    if (adds_item_fn.(do_ast1) && keeps_same_fn.(do_ast2) && keeps_same_fn.(else_ast1) &&
          adds_item_fn.(else_ast2)) ||
         (keeps_same_fn.(do_ast1) && adds_item_fn.(do_ast2) && adds_item_fn.(else_ast1) &&
            keeps_same_fn.(else_ast2)) do
      "Enum.split_with"
    end
  end

  defp reduce_reducible_to(_initial_value, _item_ast, _acc_ast, _ast) do
    nil
  end

  # defp reduce_reducible_to(initial_value, item_ast, acc_ast, ast) do
  #   dbg()
  #   nil
  # end

  # For when there is an `if` where one part returns just the accumulator
  defp if_is_reducible_to(
         initial_value,
         _item_ast,
         acc_var,
         {:+, _, [{acc_var, _, nil}, value]}
       )
       when is_integer(initial_value) and is_integer(value) do
    "Enum.count"
  end

  defp if_is_reducible_to(
         initial_value,
         _item_ast,
         acc_var,
         {:+, _, [value, {acc_var, _, nil}]}
       )
       when is_integer(initial_value) and is_integer(value) do
    "Enum.count"
  end

  defp if_is_reducible_to(
         initial_value,
         _item_ast,
         _acc_var,
         _
       ) do
    if initial_value == [] or match?({:%{}, _, _}, initial_value) do
      ["Enum.filter", "Enum.reject"]
    end
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
