defmodule Argx.Matcher do
  @moduledoc false

  alias Argx.Util, as: U

  def match(m, f, [_ | _] = args_map, %{} = configs) when is_atom(m) and is_atom(f) do
    f |> are_keys_equal!(args_map, configs)

    set_default(m, configs, args_map) |> Keyword.values()
  end

  ###
  defp set_default(m, %{} = configs, [_ | _] = args_map) do
    do_set_default(m, configs, args_map, [])
  end

  defp do_set_default(_, _, [], acc) do
    acc |> Enum.reverse()
  end

  defp do_set_default(m, configs, [{k, nil} | rest], acc) do
    v = configs |> Map.get(k) |> Map.get(:default) |> get_default(m)
    do_set_default(m, configs, rest, [{k, v} | acc])
  end

  defp do_set_default(m, configs, [{_, _} = kv | rest], acc) do
    do_set_default(m, configs, rest, [kv | acc])
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
