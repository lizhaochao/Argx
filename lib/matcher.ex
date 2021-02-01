defmodule Argx.Matcher do
  @moduledoc false

  alias Argx.Util, as: U

  def match(m, f, [_ | _] = args_kw, %{} = configs) when is_atom(m) and is_atom(f) do
    f |> are_keys_equal!(args_kw, configs)

    configs = args_kw |> Keyword.keys() |> U.sort_by_keys(configs)
    set_default(m, configs, args_kw) |> Keyword.values()
  end

  ###
  defp set_default(m, [_ | _] = configs, [_ | _] = args_kw) do
    do_set_default(m, configs, args_kw, [])
  end

  defp do_set_default(_, _, [], acc) do
    acc |> Enum.reverse()
  end

  defp do_set_default(m, [{k1, %Argx.Config{default: default}} | rest1], [{k2, nil} | rest2], acc)
       when k1 == k2 and not is_nil(default) do
    default = get_default(default, m)
    do_set_default(m, rest1, rest2, [{k2, default} | acc])
  end

  defp do_set_default(m, [{k1, _} | rest1], [{k2, _} = kv | rest2], acc)
       when k1 == k2 do
    do_set_default(m, rest1, rest2, [kv | acc])
  end

  defp get_default({{:., _, [{:__aliases__, _, [_ | _] = m}, f]}, _, a}, _) do
    m
    |> U.make_module_name()
    |> apply(f, a)
  end

  defp get_default({f, _, a}, m) do
    apply(m, f, a)
  end

  defp get_default(value, _) do
    value
  end

  ###
  defp are_keys_equal!(f, [_ | _] = args, %{} = configs) when is_atom(f) do
    keys1 = args |> Keyword.keys() |> Enum.sort()
    keys2 = configs |> Map.keys() |> Enum.sort()

    if keys1 == keys2 do
      :ignore
    else
      raise "#{f} function has arg not config"
    end
  end
end
