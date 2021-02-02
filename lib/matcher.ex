defmodule Argx.Matcher do
  @moduledoc false

  import Argx.{Checker, Converter, Defaulter, Util}

  def match(m, f, [_ | _] = args_kw, %{} = configs) when is_atom(m) and is_atom(f) do
    f |> are_keys_equal!(args_kw, configs)

    configs = args_kw |> Keyword.keys() |> sort_by_keys(configs)

    args_kw
    |> set_default(configs, m)
    |> convert(configs, m)
    |> lacked(configs, m)
    |> Keyword.values()
  end

  defp lacked(args_kw, configs, m) do
    do_lacked(args_kw, configs, args_kw, [])
  end

  defp do_lacked([], [], rest_args_kw, []) do
    rest_args_kw
  end

  defp do_lacked([], [], rest_args_kw, acc) do
    acc |> Enum.reverse()
  end

  defp do_lacked(
         [{k1, nil} | rest1],
         [{k2, %Argx.Config{optional: false}} | rest2],
         rest_args_kw,
         acc
       )
       when k1 == k2 do
    {nil, acc} =
      Keyword.get_and_update(acc, :lacked, fn current ->
        new_value = ((current && [k1 | current]) || [k1]) |> Enum.reverse()
        {nil, new_value}
      end)

    {nil, rest3} = Keyword.pop(rest_args_kw, k1)

    do_lacked(rest1, rest2, rest3, acc)
  end

  defp do_lacked(
         [{k1, _} = kv | rest1],
         [{k2, _} | rest2],
         rest_args_kw,
         acc
       )
       when k1 == k2 do
    do_lacked(rest1, rest2, rest_args_kw, acc)
  end
end
