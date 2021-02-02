defmodule Argx.Matcher do
  @moduledoc false

  import Argx.{Checker, Converter, Defaulter, Parser, Util}

  def match(m, f, [_ | _] = args_kw, %{} = configs) when is_atom(m) and is_atom(f) do
    are_keys_equal!(f, args_kw, configs)

    configs =
      args_kw
      |> Keyword.keys()
      |> sort_by_keys(configs)

    args_kw =
      args_kw
      |> set_default(configs, m)
      |> convert(configs, m)

    {[], args_kw, configs}
    |> lacked()
    |> drop_checked_keys(args_kw, configs)
    |> error_type()
    |> drop_checked_keys(args_kw, configs)
    |> out_of_range()
    |> post_match(args_kw)
  end

  def match(_, _, _, _) do
    :match_error
  end

  ###
  defp lacked({acc_errors, args_kw, configs}) do
    do_lacked(acc_errors, args_kw, configs)
  end

  defp do_lacked([], [], []) do
    []
  end

  defp do_lacked(acc_errors, [], []) do
    {:error, acc_errors}
  end

  defp do_lacked(
         acc_errors,
         [{k1, nil} | rest1],
         [{k2, %Argx.Config{optional: false}} | rest2]
       )
       when k1 == k2 do
    acc_errors
    |> do_acc_errors(:lacked, k1)
    |> do_lacked(rest1, rest2)
  end

  defp do_lacked(
         acc_errors,
         [{k1, _} | rest1],
         [{k2, _} | rest2]
       )
       when k1 == k2 do
    do_lacked(acc_errors, rest1, rest2)
  end

  ###
  defp error_type({acc_errors, args_kw, configs}) do
    do_error_type(acc_errors, args_kw, configs)
  end

  defp do_error_type([], [], []) do
    []
  end

  defp do_error_type(acc_errors, [], []) do
    {:error, acc_errors}
  end

  defp do_error_type(
         acc_errors,
         [{k1, nil} | rest1],
         [{k2, %Argx.Config{optional: true}} | rest2]
       )
       when k1 == k2 do
    do_error_type(acc_errors, rest1, rest2)
  end

  defp do_error_type(
         acc_errors,
         [{k1, v1} | rest1],
         [{k2, %Argx.Config{type: type}} | rest2]
       )
       when k1 == k2 do
    if some_type?(v1, type) do
      acc_errors
    else
      do_acc_errors(acc_errors, :error_type, k1)
    end
    |> do_error_type(rest1, rest2)
  end

  ###
  defp out_of_range({acc_errors, args_kw, configs}) do
    do_out_of_range(acc_errors, args_kw, configs)
  end

  defp do_out_of_range([], [], []) do
    []
  end

  defp do_out_of_range(acc_errors, [], []) do
    {:error, acc_errors}
  end

  defp do_out_of_range(
         acc_errors,
         [{k1, nil} | rest1],
         [{k2, %Argx.Config{optional: true}} | rest2]
       )
       when k1 == k2 do
    do_out_of_range(acc_errors, rest1, rest2)
  end

  defp do_out_of_range(
         acc_errors,
         [{k1, _} | rest1],
         [{k2, %Argx.Config{range: nil}} | rest2]
       )
       when k1 == k2 do
    do_out_of_range(acc_errors, rest1, rest2)
  end

  defp do_out_of_range(
         acc_errors,
         [{k1, v1} | rest1],
         [{k2, %Argx.Config{type: type, range: range}} | rest2]
       )
       when k1 == k2 do
    if in_range?(v1, parse_range(range), type) do
      acc_errors
    else
      do_acc_errors(acc_errors, :out_of_range, k1)
    end
    |> do_out_of_range(rest1, rest2)
  end

  ###
  defp do_acc_errors(acc, type, field) do
    {nil, acc} =
      Keyword.get_and_update(acc, type, fn current ->
        new_value = (current && [field | current]) || [field]
        {nil, new_value}
      end)

    acc
  end

  defp drop_checked_keys([], args_kw, configs) do
    {[], args_kw, configs}
  end

  defp drop_checked_keys(errors, args_kw, configs) do
    {errors, args_kw, configs} |> drop_checked_keys()
  end

  defp drop_checked_keys({[], args_kw, configs}) do
    {[], args_kw, configs}
  end

  defp drop_checked_keys({{:error, errors}, args_kw, configs}) do
    errors |> do_drop_checked_keys(args_kw, configs, errors)
  end

  defp do_drop_checked_keys([], args_kw, configs, errors) do
    {errors, args_kw, configs}
  end

  defp do_drop_checked_keys([{_type, keys} | rest], args_kw, configs, errors) do
    args_kw = Keyword.drop(args_kw, keys)
    configs = Keyword.drop(configs, keys)
    rest |> do_drop_checked_keys(args_kw, configs, errors)
  end

  defp post_match({:error, errors}, _) do
    errors =
      errors
      |> Enum.reverse()
      |> Enum.map(fn {type, fields} ->
        {type, Enum.reverse(fields)}
      end)

    {:error, errors}
  end

  defp post_match([], args_kw) do
    Keyword.values(args_kw)
  end
end
