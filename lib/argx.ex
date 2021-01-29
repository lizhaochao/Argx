defmodule Argx do
  @moduledoc false

  import Argx.Config, only: [gen_configs: 1, do_defconfig: 2]

  alias Argx.Checker, as: C
  alias Argx.Parser, as: P

  defmacro defconfig(name, configs) do
    C.check_defconfig(name, configs)
    do_defconfig(name, configs)
  end

  defmacro with_check(configs, do: block) do
    %{
      f: f,
      a: a,
      guard: guard,
      block: block
    } = P.parse_fun(block)

    quote do
      unquote(gen_configs(configs))

      def unquote(f)(unquote_splicing(a)) when unquote(guard) do
        unquote(block)
      end

      def unquote(make_real_f_name(f))(unquote_splicing(a)) do
        unquote(block)
      end
    end
  end

  defp make_real_f_name(f) do
    f
    |> real_f_name_rule()
    |> IO.iodata_to_binary()
    |> String.to_atom()
  end

  defp real_f_name_rule(f) when is_bitstring(f) do
    ["real", "_", f, "__", "macro"]
  end

  defp real_f_name_rule(f) when is_atom(f) do
    to_string(f) |> real_f_name_rule()
  end

  defp real_f_name_rule(_) do
    []
  end
end
