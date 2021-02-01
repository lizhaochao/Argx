defmodule Argx.Defaulter do
  @moduledoc false

  import Argx.Util

  def set_default([_ | _] = args_kw, [_ | _] = configs, m) do
    do_set_default(args_kw, configs, m, [])
  end

  defp do_set_default([], [], _, acc) do
    acc |> Enum.reverse()
  end

  defp do_set_default(
         [{k1, nil} | rest1],
         [{k2, %Argx.Config{default: default}} | rest2],
         m,
         acc
       )
       when k1 == k2 and not is_nil(default) do
    default = get_default(default, m)
    do_set_default(rest1, rest2, m, [{k1, default} | acc])
  end

  defp do_set_default(
         [{k1, _} = kv | rest1],
         [{k2, _} | rest2],
         m,
         acc
       )
       when k1 == k2 do
    do_set_default(rest1, rest2, m, [kv | acc])
  end

  defp get_default({{:., _, [{:__aliases__, _, [_ | _] = m}, f]}, _, a}, _) do
    m
    |> make_module_name()
    |> apply(f, a)
  end

  defp get_default({f, _, a}, m) do
    apply(m, f, a)
  end

  defp get_default(value, _) do
    value
  end
end
