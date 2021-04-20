defmodule Argx.Defconfig.Use do
  @moduledoc false

  alias Argx.{Checker, Const, Parser, Util}
  alias Argx.Defconfig.Use, as: Self

  defmacro __using__(_opts) do
    quote do
      defmacro defconfig(name, configs) do
        Checker.check_defconfig!(name, configs)

        name = Parser.parse_defconfig_name(name)
        configs = Parser.parse_configs(configs)
        attr = Macro.escape(%{name => configs})
        f_name = Self.make_get_f_name(name)

        quote do
          unquote(Self.reg_attr())

          Module.put_attribute(
            __MODULE__,
            unquote(Const.defconfigs_key()),
            unquote(attr)
          )

          def unquote(f_name)() do
            unquote(attr)
          end
        end
      end
    end
  end

  def make_get_f_name(name) do
    ["__get", Const.defconfigs_key(), name, "__"]
    |> Util.to_fun_name()
  end

  def reg_attr do
    quote do
      Module.register_attribute(
        __MODULE__,
        unquote(Const.defconfigs_key()),
        accumulate: true,
        persiste: true
      )
    end
  end
end

defmodule Argx.WithCheck.Use do
  @moduledoc false

  alias Argx.{Checker, Const, Formatter, Matcher, Parser, Util}
  alias Argx.WithCheck.Use, as: Self

  defmacro __using__(general_m) do
    quote do
      @defconfigs {:@, [], [{Const.defconfigs_key(), [], nil}]}

      defmacro with_check(configs, do: block) do
        Checker.check!(configs, block)

        use_m = __MODULE__
        funs = Parser.parse_fun(block)
        general_m = unquote(general_m)

        configs =
          general_m
          |> Self.get_general_configs()
          |> Macro.escape()
          |> Self.merge_defconfigs(@defconfigs)
          |> Self.merge_configs(configs)

        ignore_attr_warning_expr =
          quote do
            unquote(Self.reg_attr())
          end

        are_keys_equal_expr =
          quote do
            [%{f: f, a: a} | _] = unquote(Macro.escape(funs))
            arg_names = Self.get_arg_names(a)
            Checker.are_keys_equal!(f, arg_names, unquote(configs))
          end

        Enum.map(funs, fn fun ->
          %{f: f, a: a, guard: guard, block: block} = fun
          real_f_name = Self.make_real_f_name(f)

          quote do
            # Decorator will decorate the closest function.
            def unquote(real_f_name)(unquote_splicing(a)) when unquote(guard) do
              unquote(block)
            end

            unquote(ignore_attr_warning_expr)
            unquote(are_keys_equal_expr)

            def unquote(f)(unquote_splicing(a)) when unquote(guard) do
              args = unquote(Self.make_args(a))

              __MODULE__
              |> Matcher.match(args, unquote(configs))
              |> Self.post_match(
                unquote(use_m),
                unquote(general_m),
                __MODULE__,
                unquote(real_f_name)
              )
            end
          end
        end)
      end
    end
  end

  ###
  def post_match({:error, _} = err, use_m, general_m, current_m, _) do
    Formatter.fmt_errors(err, use_m, general_m, current_m)
  end

  def post_match([_ | _] = new_args, _use_m, _general_m, current_m, real_f_name) do
    apply(current_m, real_f_name, new_args)
  end

  ###
  def make_args(a) do
    quote do
      keys = unquote(get_arg_names(a))
      values = [unquote_splicing(a)]
      Self.do_make_args(keys, values, [])
    end
  end

  def do_make_args([] = _keys, [] = _values, args), do: Enum.reverse(args)
  def do_make_args([_ | _] = _keys, [] = _values, args), do: args
  def do_make_args([] = _keys, [_ | _] = _values, args), do: args

  def do_make_args([key | key_rest], [value | value_rest], args) do
    new_args = Keyword.put(args, key, value)
    do_make_args(key_rest, value_rest, new_args)
  end

  def get_arg_names(args), do: do_get_arg_names(args, [])
  defp do_get_arg_names([], names), do: Enum.reverse(names)
  defp do_get_arg_names([{arg, _, _} | rest], names), do: do_get_arg_names(rest, [arg | names])
  defp do_get_arg_names([_other_expr | rest], names), do: do_get_arg_names(rest, names)

  ###
  def merge_defconfigs(general_configs, defconfigs) do
    quote do
      Map.merge(
        unquote(general_configs),
        Util.list_to_map(unquote(defconfigs))
      )
    end
  end

  def merge_configs(defconfigs, configs) do
    quote do
      {names, configs} =
        Map.pop(
          unquote(configs |> Parser.parse_configs() |> Macro.escape()),
          unquote(Const.names_key())
        )

      names
      |> Self.get_configs_by_names(unquote(defconfigs))
      |> Map.merge(configs)
    end
  end

  def get_configs_by_names([name | _] = defconfig_names, defconfigs) when is_atom(name) do
    Enum.reduce(defconfig_names, %{}, fn name, configs ->
      config = Map.get(defconfigs, name)
      (config && Map.merge(configs, config)) || configs
    end)
  end

  def get_configs_by_names(_other_defconfig_names, _defconfigs), do: %{}

  def get_general_configs([]), do: %{}
  def get_general_configs(general_m), do: apply(general_m, :__get_defconfigs__, [])

  ###
  def make_real_f_name(f), do: Util.make_fun_name("real", f)

  def reg_attr do
    quote do
      Module.register_attribute(
        __MODULE__,
        unquote(Const.defconfigs_key()),
        accumulate: true,
        persiste: true
      )
    end
  end
end
