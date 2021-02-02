defmodule Argx do
  @moduledoc false

  alias Argx.Const, as: Con
  alias Argx.Checker, as: C
  alias Argx.Parser, as: P
  alias Argx.Util, as: U
  alias Argx.Matcher, as: M

  @defconfigs {:@, [], [{Con.defconfigs_key(), [], nil}]}
  @names_key Con.names_key()

  ###
  defmacro defconfig(name, configs) do
    C.check_defconfig!(name, configs)

    name = P.parse_defconfig_name(name)
    configs = P.parse_configs(configs)
    attr = %{name => configs} |> Macro.escape()

    quote do
      unquote(reg_attr())

      Module.put_attribute(
        __MODULE__,
        unquote(Con.defconfigs_key()),
        unquote(attr)
      )
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
      # ignore undefined module attribute warning
      unquote(reg_attr())

      def unquote(f)(unquote_splicing(a)) when unquote(guard) do
        args = unquote(make_args(a))
        configs = unquote(merge_configs(configs, @defconfigs))
        resp = M.match(__MODULE__, unquote(f), args, configs)

        case resp do
          {:error, _} = err ->
            err

          new_args when is_list(new_args) ->
            apply(__MODULE__, unquote(make_real_f_name(f)), new_args)
        end
      end

      def unquote(make_real_f_name(f))(unquote_splicing(a)) do
        unquote(block)
      end
    end
  end

  ###
  defp make_args(a) do
    quote do
      keys = unquote(a |> get_arg_names([]))
      values = [unquote_splicing(a)]
      keys |> do_make_args(values, [])
    end
  end

  def do_make_args([], [], acc) do
    acc |> Enum.reverse()
  end

  def do_make_args([_ | _], [], acc) do
    acc
  end

  def do_make_args([], [_ | _], acc) do
    acc
  end

  def do_make_args([key | k_rest], [value | v_rest], acc) do
    k_rest |> do_make_args(v_rest, Keyword.put(acc, key, value))
  end

  defp get_arg_names([], acc) do
    acc |> Enum.reverse()
  end

  defp get_arg_names([{arg, _, _} | rest], acc) do
    rest |> get_arg_names([arg | acc])
  end

  defp get_arg_names([_ | rest], acc) do
    rest |> get_arg_names(acc)
  end

  ###
  defp merge_configs(configs, defconfigs) do
    quote do
      {names, configs} =
        unquote(configs |> P.parse_configs() |> Macro.escape())
        |> Map.pop(unquote(@names_key))

      names
      |> get_configs_by_names(unquote(defconfigs))
      |> Map.merge(configs)
    end
  end

  def get_configs_by_names([_ | _] = names, defconfigs) do
    names
    |> Enum.reduce(%{}, fn name, acc ->
      configs = defconfigs |> U.list_to_map() |> Map.get(name, nil)
      (configs && acc |> Map.merge(configs)) || acc
    end)
  end

  def get_configs_by_names(_, _) do
    %{}
  end

  ###
  defp make_real_f_name(f) do
    U.make_fun_name("real", f)
  end

  defp reg_attr do
    quote do
      Module.register_attribute(
        __MODULE__,
        unquote(Con.defconfigs_key()),
        accumulate: true,
        persiste: true
      )
    end
  end
end
