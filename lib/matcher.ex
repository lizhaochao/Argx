defmodule Argx.Matcher do
  @moduledoc false

  alias Argx.Util, as: U

  def match(m, f, [_ | _] = args_kw, %{} = configs) when is_atom(m) and is_atom(f) do
    f |> are_keys_equal!(args_kw, configs)

    configs = args_kw |> Keyword.keys() |> U.sort_by_keys(configs)

    args_kw
    |> set_default(configs, m)
    |> convert(configs, m)
    |> Keyword.values()
  end

  ###
  defp convert([_ | _] = args_kw, [_ | _] = configs, m) do
    do_convert(args_kw, configs, m, [])
  end

  defp do_convert([], [], _, acc) do
    acc |> Enum.reverse()
  end

  defp do_convert(
         [{k1, v1} | rest1],
         [{k2, %Argx.Config{auto: true, type: type}} | rest2],
         m,
         acc
       )
       when k1 == k2 and not is_nil(v1) do
    v1 =
      case to_type(v1, type) do
        :error -> raise "auto convert error"
        value -> value
      end

    do_convert(rest1, rest2, m, [{k1, v1} | acc])
  end

  defp do_convert(
         [{k1, _} = kv | rest1],
         [{k2, _} | rest2],
         m,
         acc
       )
       when k1 == k2 do
    do_convert(rest1, rest2, m, [kv | acc])
  end

  defp to_type(value, :integer) when is_bitstring(value) do
    String.to_integer(value)
  end

  defp to_type(value, :float) when is_bitstring(value) do
    String.to_float(value)
  end

  defp to_type(value, :float) when is_integer(value) do
    value / 1.0
  end

  defp to_type(_, _) do
    :error
  end

  ###
  defp set_default([_ | _] = args_kw, [_ | _] = configs, m) do
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
