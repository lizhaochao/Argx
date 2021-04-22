defmodule Argx.Use.Defconfig do
  @moduledoc false

  alias Argx.{Checker, Const, Parser, Util}
  alias Argx.Use.Defconfig, as: Self
  alias Argx.Use.Helper

  defmacro __using__(_opts) do
    quote do
      defmacro defconfig(name, configs) do
        Checker.check_defconfig!(name, configs)

        name = Parser.parse_defconfig_name(name)
        configs = Parser.parse_configs(configs)
        attr = Macro.escape(%{name => configs})
        f_name = Helper.make_get_general_configs_f_name(name)

        operate_attr_expr =
          quote do
            unquote(Helper.reg_attr(Const.defconfigs_key()))
            unquote(Helper.put_attr(Const.defconfigs_key(), attr))
          end

        configs_fun_expr =
          quote do
            def unquote(f_name)() do
              unquote(attr)
            end
          end

        [operate_attr_expr] ++ [configs_fun_expr]
      end
    end
  end
end

defmodule Argx.Use.WithCheck do
  @moduledoc false

  alias Argx.{Checker, Const, Formatter, Matcher, Parser, Util}
  alias Argx.Use.WithCheck, as: Self
  alias Argx.Use.Helper

  defmacro __using__(general_m) do
    quote do
      @defconfigs {:@, [], [{Const.defconfigs_key(), [], nil}]}

      defmacro with_check(configs, do: block) do
        Checker.check!(configs, block)

        funs = Parser.parse_fun(block)
        [fun | _] = funs
        f = Map.get(fun, :f)
        a = Map.get(fun, :a)

        use_m = __MODULE__
        general_m = unquote(general_m)
        arg_names = Self.get_arg_names(a)
        configs_f_name = Helper.make_get_fun_configs_f_name(f)

        configs =
          general_m
          |> Self.get_general_configs()
          |> Macro.escape()
          |> Self.merge_defconfigs(@defconfigs)
          |> Self.merge_configs(configs, arg_names)

        # expr
        ignore_attr_warning_expr = quote do: unquote(Helper.reg_attr(Const.defconfigs_key()))

        are_keys_equal_expr =
          quote do: Checker.are_keys_equal!(unquote(f), unquote(arg_names), unquote(configs))

        funs_expr =
          Enum.map(funs, fn fun ->
            %{f: f, a: a, guard: guard, block: block} = fun
            real_f_name = Helper.make_real_f_name(f)

            quote do
              # Decorator will decorate the closest function.
              def unquote(real_f_name)(unquote_splicing(a)) when unquote(guard) do
                unquote(block)
              end

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

        configs_fun_expr =
          quote do
            def unquote(configs_f_name)() do
              unquote(configs)
            end
          end

        [ignore_attr_warning_expr] ++ [are_keys_equal_expr] ++ funs_expr ++ [configs_fun_expr]
      end
    end
  end

  ###
  def post_match({{:error, errors}, _args}, use_m, general_m, current_m, _) do
    errors =
      errors
      |> Enum.reverse()
      |> Enum.map(fn {type, fields} ->
        {type, Enum.reverse(fields)}
      end)

    Formatter.fmt_errors({:error, errors}, use_m, general_m, current_m)
  end

  def post_match({_errors, [_ | _] = new_args}, _use_m, _general_m, current_m, real_f_name) do
    apply(current_m, real_f_name, Keyword.values(new_args))
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

  def merge_configs(defconfigs, configs, arg_names) do
    quote do
      {names, configs} =
        Map.pop(
          unquote(configs |> Parser.parse_configs() |> Macro.escape()),
          unquote(Const.names_key())
        )

      merged_configs =
        unquote(defconfigs)
        |> Util.get_configs_by_names(names)
        |> Map.merge(configs)

      Util.sort_by_keys(
        merged_configs,
        unquote(arg_names)
      )
    end
  end

  def get_general_configs([]), do: %{}
  def get_general_configs(general_m), do: apply(general_m, :__get_defconfigs__, [])
end

defmodule Argx.Use.Helper do
  @moduledoc false

  alias Argx.{Const, Util}

  @defconfigs_key Const.defconfigs_key()

  ### make function name
  def make_get_general_configs_f_name(name) do
    Util.make_fun_name("get#{@defconfigs_key}#{name}")
  end

  def make_get_fun_configs_f_name(f), do: Util.make_fun_name("get_#{f}_configs")
  def make_real_f_name(f), do: Util.make_fun_name("real_#{f}")

  ### operate attr
  def reg_attr(name) do
    quote do
      Module.register_attribute(
        __MODULE__,
        unquote(name),
        accumulate: true,
        persiste: true
      )
    end
  end

  def put_attr(name, attr) do
    quote do
      Module.put_attribute(
        __MODULE__,
        unquote(name),
        unquote(attr)
      )
    end
  end
end
