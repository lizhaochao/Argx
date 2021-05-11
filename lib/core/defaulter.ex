defmodule Argx.Defaulter do
  @moduledoc false

  alias Argx.{Checker, Error}

  def set_default(
        {arg_name, _arg_value} = arg,
        {arg_name2, %Argx.Config{}} = config,
        module
      )
      when arg_name == arg_name2 do
    do_set_default(arg, config, module)
  end

  def set_default(_other_arg, _other_config, _module) do
    raise Error, "maybe there are some args that not found configs."
  end

  defp do_set_default(
         {arg_name, arg_value} = arg,
         {_, %Argx.Config{default: default}},
         module
       )
       when not is_nil(default) do
    with true <- is_nil(arg_value) or Checker.empty?(arg_value),
         new_arg_value <- get_default(default, module) do
      {arg_name, new_arg_value}
    else
      _ -> arg
    end
  end

  defp do_set_default(
         {_arg_name, _arg_value} = arg,
         {_, _},
         _module
       ) do
    arg
  end

  def get_default(v, _m)
      when is_number(v) or is_boolean(v) or
             is_bitstring(v) or is_atom(v) or
             is_list(v) or is_map(v) do
    v
  end

  def get_default(
        {{:., _, [{:__aliases__, _, [_ | _] = m}, f]}, _, a},
        _m
      ) do
    m
    |> make_module_name()
    |> apply(f, a)
  end

  def get_default(
        {f, _, a},
        m
      )
      when f != :fn and f != :& do
    apply(m, f, a)
  end

  def get_default({:fn, _, _}, _m), do: raise(Error, "not support anonymous function")
  def get_default({:&, _, _}, _m), do: raise(Error, "not support function reference")
  def get_default(_other, _m), do: raise(Error, "unknown value type")

  ###
  def make_module_name([term | _] = parts) when is_atom(term) or is_bitstring(term) do
    [Elixir | parts]
    |> Enum.map(fn part -> to_string(part) end)
    |> Enum.join(".")
    |> String.to_atom()
  end

  def make_module_name(_other), do: nil
end
