defmodule Argx.Defaulter do
  @moduledoc false

  import Argx.Util

  def set_default(
        [{_arg_name1, _arg_value1} | _] = args,
        [{_arg_name2, %Argx.Config{}} | _] = configs,
        module
      ) do
    do_set_default(args, configs, module, [])
  end

  defp do_set_default([], [], _, values), do: Enum.reverse(values)

  defp do_set_default(
         [{k1, nil} | rest1],
         [{k2, %Argx.Config{default: default}} | rest2],
         module,
         values
       )
       when k1 == k2 and not is_nil(default) do
    default = get_default(default, module)
    do_set_default(rest1, rest2, module, [{k1, default} | values])
  end

  defp do_set_default(
         [{k1, _} = kv | rest1],
         [{k2, _} | rest2],
         module,
         values
       )
       when k1 == k2 do
    do_set_default(rest1, rest2, module, [kv | values])
  end

  defp get_default({{:., _, [{:__aliases__, _, [_ | _] = m}, f]}, _, a}, _) do
    m
    |> make_module_name()
    |> apply(f, a)
  end

  defp get_default({f, _, a}, m), do: apply(m, f, a)
  defp get_default(value, _), do: value
end
