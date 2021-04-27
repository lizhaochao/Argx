defmodule Argx.Converter do
  @moduledoc false

  def convert(
        {arg_name, _arg_value} = args,
        {arg_name2, %Argx.Config{}} = configs
      )
      when arg_name == arg_name2 do
    do_convert(args, configs)
  end

  def convert(_other_arg, _other_config), do: raise(Argx.Error, "not in the same order.")

  defp do_convert(
         {arg_name, arg_value},
         {_, %Argx.Config{auto: true, type: type}}
       )
       when not is_nil(arg_value) do
    with new_arg_value <- to_type(arg_value, type) do
      {arg_name, new_arg_value}
    end
  end

  defp do_convert(
         {_arg_name, _arg_value} = arg,
         {_, _}
       ) do
    arg
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

  def to_type(true, :boolean), do: true
  def to_type(false, :boolean), do: false
  def to_type(1, :boolean), do: true
  def to_type(0, :boolean), do: false
  def to_type("1", :boolean), do: true
  def to_type("0", :boolean), do: false

  def to_type(value, _other_type), do: value
end
