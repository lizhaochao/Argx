defmodule Argx do
  @moduledoc false

  alias Argx.Const, as: Con
  alias Argx.Checker, as: C
  alias Argx.Parser, as: P
  alias Argx.Util, as: U

  defmacro defconfig(name, configs) do
    C.check_defconfig!(name, configs)

    name = P.parse_defconfig_name(name)
    configs = P.parse_configs(configs)
    attr = %{name => configs}

    quote do
      Module.register_attribute(__MODULE__, unquote(Con.store_key()), accumulate: true)
      Module.put_attribute(__MODULE__, unquote(Con.store_key()), unquote(Macro.escape(attr)))
    end
  end

  defmacro with_check(configs, do: block) do
    C.check!(configs, block)

    %{
      f: f,
      a: a,
      guard: guard,
      block: block
    } = P.parse_fun(block)

    quote do
      unquote(merge_configs(configs))

      def unquote(f)(unquote_splicing(a)) when unquote(guard) do
        unquote(block)
      end

      def unquote(make_real_f_name(f))(unquote_splicing(a)) do
        unquote(block)
      end
    end
  end

  ###
  defp merge_configs(configs) do
    quote do
      defconfigs = Module.get_attribute(__MODULE__, unquote(Con.store_key())) |> U.list_to_map()
      configs = unquote(configs |> P.parse_configs() |> Macro.escape())
      {names, configs} = Map.pop(configs, :__names__)

      names
      |> U.get_all_by_names(defconfigs)
      |> Map.merge(configs)
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
