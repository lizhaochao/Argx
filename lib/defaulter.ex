defmodule Argx.Defaulter do
  @moduledoc false

  alias Argx.Util

  def set_default(
        [{arg_name, _arg_value} | _] = args,
        [{arg_name2, %Argx.Config{}} | _] = configs,
        module
      )
      when arg_name == arg_name2 do
    do_set_default(args, configs, module, [])
  end

  def set_default([_ | _], [_ | _], _module), do: raise(Argx.Error, "not in the same order.")
  def set_default([], [_ | _], _module), do: raise(Argx.Error, "args is empty")
  def set_default([_ | _], [], _module), do: raise(Argx.Error, "configs is empty")
  def set_default([], [], _module), do: raise(Argx.Error, "both args and configs are empty")

  defp do_set_default([] = _args, [] = _configs, _module, new_args), do: Enum.reverse(new_args)

  defp do_set_default(
         [{arg_name, nil} | arg_rest],
         [{_, %Argx.Config{default: default}} | config_rest],
         module,
         new_args
       )
       when not is_nil(default) do
    new_arg_value = get_default(default, module)
    do_set_default(arg_rest, config_rest, module, [{arg_name, new_arg_value} | new_args])
  end

  defp do_set_default(
         [{_arg_name, _arg_value} = arg | arg_rest],
         [{_, _} | config_rest],
         module,
         new_args
       ) do
    do_set_default(arg_rest, config_rest, module, [arg | new_args])
  end

  def get_default(v, _m)
      when is_number(v) or is_boolean(v) or
             is_bitstring(v) or is_atom(v) or
             is_list(v) or is_map(v) do
    v
  end

  def get_default(
        {{:., _, [{:__aliases__, _, [_ | _] = m}, f]}, _, [] = a},
        _m
      ) do
    m
    |> Util.make_module_name()
    |> apply(f, a)
  end

  def get_default(
        {f, _, [] = a},
        m
      )
      when f != :fn and f != :& do
    apply(m, f, a)
  end

  def get_default({:fn, _, _}, _m), do: raise(Argx.Error, "not support anonymous function")
  def get_default({:&, _, _}, _m), do: raise(Argx.Error, "not support function reference")
  def get_default(_other, _m), do: raise(Argx.Error, "unknown value type")
end
