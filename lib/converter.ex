defmodule Argx.Converter do
  @moduledoc false

  def convert(
        [{_arg_name1, _arg_value1} | _] = args,
        [{_arg_name2, %Argx.Config{}} | _] = configs,
        module
      ) do
    do_convert(args, configs, module, [])
  end

  defp do_convert([], [], _, new_args), do: Enum.reverse(new_args)

  defp do_convert(
         [{arg_name1, arg_value1} | rest1],
         [{arg_name2, %Argx.Config{auto: true, type: type}} | rest2],
         module,
         new_args
       )
       when arg_name1 == arg_name2 and not is_nil(arg_value1) do
    new_arg_value1 = to_type(arg_value1, type)
    do_convert(rest1, rest2, module, [{arg_name1, new_arg_value1} | new_args])
  end

  defp do_convert(
         [{arg_name1, _} = arg | rest1],
         [{arg_name2, _} | rest2],
         module,
         new_args
       )
       when arg_name1 == arg_name2 do
    do_convert(rest1, rest2, module, [arg | new_args])
  end

  defp to_type(value, :integer) when is_bitstring(value) do
    value
    |> Integer.parse()
    |> case do
      {integer, ""} -> integer
      _ -> value
    end
  end

  defp to_type(value, :float) when is_bitstring(value) do
    value
    |> Float.parse()
    |> case do
      {float, ""} -> float
      _ -> value
    end
  end

  defp to_type(value, :integer) when is_integer(value), do: value
  defp to_type(value, :float) when is_float(value), do: value
  defp to_type(value, :float) when is_integer(value), do: value / 1.0
  defp to_type(value, _other_type), do: value
end
