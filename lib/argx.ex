defmodule Argx do
  @moduledoc false

  import Argx.Config, only: [gen_configs: 1, do_defconfig: 2]
  import Argx.Parser

  defmacro defconfig(name, configs) do
    do_defconfig(name, configs)
  end

  defmacro with_check(configs, do: block) do
    %{
      f: f,
      a: a,
      guard: guard,
      block: block
    } = parse_fun(block)

    quote do
      configs = unquote(gen_configs(configs))
      %{} |> Map.put(unquote(f), configs)

      def unquote(f)(unquote_splicing(a)) when unquote(guard) do
        unquote(block)
      end

      def unquote(make_real_f_name(f))(unquote_splicing(a)) do
        unquote(block)
      end
    end
  end

  defp make_real_f_name(f) do
    ["real", "_", to_string(f), "__", "macro"]
    |> IO.iodata_to_binary()
    |> String.to_atom()
  end
end
