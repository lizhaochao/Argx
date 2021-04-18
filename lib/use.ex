defmodule Argx.Defconfig.Use do
  @moduledoc false

  alias Argx.{Checker, Const, Parser}
  alias Argx.Defconfig.Use, as: Self

  defmacro __using__(_opts) do
    quote do
      defmacro defconfig(name, configs) do
        Checker.check_defconfig!(name, configs)

        name = Parser.parse_defconfig_name(name)
        configs = Parser.parse_configs(configs)
        attr = Macro.escape(%{name => configs})

        quote do
          unquote(Self.reg_attr())

          Module.put_attribute(
            __MODULE__,
            unquote(Const.defconfigs_key()),
            unquote(attr)
          )
        end
      end
    end
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

  defmacro __using__(_opts) do
    quote do
      @defconfigs {:@, [], [{Const.defconfigs_key(), [], nil}]}

      defmacro with_check(configs, do: block) do
        Checker.check!(configs, block)

        use_m = __MODULE__
        funs = Parser.parse_fun(block)
        configs = Self.merge_configs(configs, @defconfigs)

        ignore_attr_warning_expr =
          quote do
            [unquote(Self.reg_attr())]
          end

        funs_expr =
          Enum.map(funs, fn fun ->
            %{
              f: f,
              a: a,
              guard: guard,
              block: block
            } = fun

            real_f_name = Self.make_real_f_name(f)

            quote do
              def unquote(f)(unquote_splicing(a)) when unquote(guard) do
                args = unquote(Self.make_args(a))

                __MODULE__
                |> Matcher.match(unquote(f), args, unquote(configs))
                |> Self.post_match(unquote(use_m), __MODULE__, unquote(real_f_name))
              end

              def unquote(real_f_name)(unquote_splicing(a)) when unquote(guard) do
                unquote(block)
              end
            end
          end)

        ignore_attr_warning_expr ++ funs_expr
      end
    end
  end

  ###
  def post_match({:error, _} = err, use_m, current_m, _) do
    Formatter.format_errors(err, use_m, current_m)
  end

  def post_match([_ | _] = new_args, _, current_m, real_f_name) do
    apply(current_m, real_f_name, new_args)
  end

  ###
  def make_args(a) do
    quote do
      keys = unquote(get_arg_names(a, []))
      values = [unquote_splicing(a)]
      Self.do_make_args(keys, values, [])
    end
  end

  def do_make_args([] = _keys, [] = _values, args), do: Enum.reverse(args)
  def do_make_args([_ | _] = _keys, [] = _values, args), do: args
  def do_make_args([] = _keys, [_ | _] = _values, args), do: args

  def do_make_args([key | key_rest], [value | value_rest], args),
    do:
      (
        new_args = Keyword.put(args, key, value)
        do_make_args(key_rest, value_rest, new_args)
      )

  defp get_arg_names([], names), do: Enum.reverse(names)
  defp get_arg_names([{arg, _, _} | rest], names), do: get_arg_names(rest, [arg | names])
  defp get_arg_names([_other_expr | rest], names), do: get_arg_names(rest, names)

  ###
  def merge_configs(configs, defconfigs) do
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

  def get_configs_by_names([name | _] = defconfig_names, defconfigs) when is_atom(name),
    do:
      Enum.reduce(defconfig_names, %{}, fn name, configs ->
        config = defconfigs |> Util.list_to_map() |> Map.get(name, nil)
        (config && Map.merge(configs, config)) || configs
      end)

  def get_configs_by_names(_other_defconfig_names, _defconfigs), do: %{}

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
