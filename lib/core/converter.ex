defmodule Argx.Converter do
  @moduledoc false

  alias Argx.Error

  def convert(
        {arg_name, _arg_value} = args,
        {arg_name2, %Argx.Config{}} = configs
      )
      when arg_name == arg_name2 do
    do_convert(args, configs)
  end

  def convert(_other_arg, _other_config) do
    raise Error, "maybe there are some args that not found configs."
  end

  defp do_convert(
         {arg_name, arg_value},
         {_, %Argx.Config{autoconvert: true, type: type}}
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

  def to_type(term, :integer) when is_bitstring(term) do
    term
    |> Integer.parse()
    |> case do
      {integer, ""} -> integer
      _ -> term
    end
  end

  def to_type(term, :integer) when is_integer(term), do: term

  def to_type(term, :float) when is_bitstring(term) do
    term
    |> Float.parse()
    |> case do
      {float, ""} -> float
      _ -> term
    end
  end

  def to_type(term, :float) when is_float(term), do: term
  def to_type(term, :float) when is_integer(term), do: term / 1.0

  def to_type(true, :boolean), do: true
  def to_type(false, :boolean), do: false
  def to_type(1, :boolean), do: true
  def to_type(0, :boolean), do: false
  def to_type("1", :boolean), do: true
  def to_type("0", :boolean), do: false

  def to_type(term, _other_type), do: term
end
