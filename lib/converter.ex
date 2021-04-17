defmodule Argx.Converter do
  @moduledoc false

  def convert(
        [{arg_name, _arg_value} | _] = args,
        [{arg_name2, %Argx.Config{}} | _] = configs
      )
      when arg_name == arg_name2 do
    do_convert(args, configs, [])
  end

  def convert([{_, _} | _], [{_, _} | _]), do: raise(Argx.Error, "not in the same order.")
  def convert([], [{_, _} | _]), do: raise(Argx.Error, "args is empty")
  def convert([{_, _} | _], []), do: raise(Argx.Error, "configs is empty")
  def convert([], []), do: raise(Argx.Error, "both args and configs are empty")

  defp do_convert([] = _args, [] = _configs, new_args), do: Enum.reverse(new_args)

  defp do_convert(
         [{arg_name, arg_value} | arg_rest],
         [{_, %Argx.Config{auto: true, type: type}} | config_rest],
         new_args
       )
       when not is_nil(arg_value) do
    new_arg_value = to_type(arg_value, type)
    do_convert(arg_rest, config_rest, [{arg_name, new_arg_value} | new_args])
  end

  defp do_convert(
         [{_arg_name, _arg_value} = arg | arg_rest],
         [{_, _} | config_rest],
         new_args
       ) do
    do_convert(arg_rest, config_rest, [arg | new_args])
  end

  def to_type(value, :integer) when is_bitstring(value) do
    value
    |> Integer.parse()
    |> case do
      {integer, ""} -> integer
      _ -> value
    end
  end

  def to_type(value, :integer) when is_integer(value), do: value

  def to_type(value, :float) when is_bitstring(value) do
    value
    |> Float.parse()
    |> case do
      {float, ""} -> float
      _ -> value
    end
  end

  def to_type(value, :float) when is_float(value), do: value
  def to_type(value, :float) when is_integer(value), do: value / 1.0

  def to_type(value, _other_type), do: value
end
