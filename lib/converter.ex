defmodule Argx.Converter do
  @moduledoc false

  def convert([_ | _] = args_kw, [_ | _] = configs, m) do
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
    v1 = to_type(v1, type)
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
    try do
      String.to_integer(value)
    rescue
      ArgumentError -> value
    end
  end

  defp to_type(value, :integer) when is_integer(value) do
    value
  end

  defp to_type(value, :float) when is_bitstring(value) do
    try do
      String.to_float(value)
    rescue
      ArgumentError -> value
    end
  end

  defp to_type(value, :float) when is_float(value) do
    value
  end

  defp to_type(value, :float) when is_integer(value) do
    value / 1.0
  end

  defp to_type(value, _) do
    value
  end
end
