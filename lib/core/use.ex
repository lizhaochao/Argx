defmodule Argx.Use do
  @moduledoc false

  alias Argx.{Config, Const, Formatter, Matcher}
  alias Argx.Matcher.Helper, as: MatcherHelper
  alias Argx.Checker.DSL, as: Checker

  alias Argx.Use, as: Self

  @defconfigs_key Const.defconfigs_key()
  @default_warn Const.default_warn()
  @warn_max_nested_depth Const.warn_max_nested_depth()

  defmacro __using__(opts) do
    shared_m = Keyword.get(opts, :share, [])
    warn = Keyword.get(opts, :warn, @default_warn)

    quote do
      def check(args, config_names) do
        Self.match(args, config_names, __MODULE__, unquote(shared_m), unquote(warn))
      end
    end
  end

  def match(args, config_names, curr_m, shared_m, warn) do
    Checker.check_args!(args)
    Checker.check_config_names!(config_names)

    with origin_type <- MatcherHelper.get_type(args),
         configs <- get_configs(shared_m, curr_m, config_names, warn),
         {args, configs} <- MatcherHelper.pre_args_configs(args, configs),
         from <- :argx do
      match = Matcher.match(from)

      match.(args, configs, curr_m)
      |> Formatter.fmt_match_result(origin_type)
      |> Formatter.fmt_errors(curr_m, shared_m)
    end
  end

  def get_configs(shared_m, curr_m, config_names, warn) do
    with config_names <- MatcherHelper.prune_names(config_names),
         modules <- [shared_m, curr_m],
         all_configs <- Config.get_configs_by_modules(modules, @defconfigs_key),
         get <- Config.get_configs_by_names(warn, @warn_max_nested_depth) do
      all_configs
      |> get.(config_names)
      |> Keyword.new()
    end
  end
end

defmodule Argx.Use.WithCheck do
  @moduledoc false

  alias Argx.{Checker, Config, Const, Formatter, Matcher, Parser}
  alias Argx.Checker.DSL, as: CheckerDSL

  alias Argx.Use.WithCheck, as: Self
  alias Argx.Use.Helper

  @default_warn Const.default_warn()
  @warn_max_nested_depth Const.warn_max_nested_depth()

  defmacro __using__(opts) do
    shared_m = Keyword.get(opts, :share, [])
    warn = Keyword.get(opts, :warn, @default_warn)

    quote do
      @names_key Const.names_key()
      @should_drop_flag Const.should_drop_flag()
      @defconfigs_key Const.defconfigs_key()
      @defconfigs_attr {:@, [], [{@defconfigs_key, [], nil}]}

      defmacro with_check(configs, do: block) do
        CheckerDSL.check!(configs, block)

        funs = Parser.parse_fun(block)
        [fun | _] = funs
        f = :maps.get(:f, fun)
        a = :maps.get(:a, fun)

        use_m = __MODULE__
        shared_m = unquote(shared_m)
        arg_names = Helper.get_arg_names(a)
        configs_f_name = Helper.make_get_fun_configs_f_name(f)
        configs = configs |> Parser.parse_configs() |> Macro.escape()

        raw_fun_configs =
          shared_m
          |> Self.get_all_defconfigs(@defconfigs_attr, @defconfigs_key)
          |> Self.merge_configs(configs, @names_key, unquote(warn))

        sorted_fun_configs =
          quote do
            Helper.sort_by_keys(
              unquote(raw_fun_configs),
              unquote(arg_names),
              unquote(@should_drop_flag)
            )
          end

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
                match = Matcher.match(:with_check)

                match.(args, unquote(sorted_fun_configs), __MODULE__)
                |> Self.post_match(
                  __MODULE__,
                  unquote(shared_m),
                  unquote(use_m),
                  unquote(real_f_name)
                )
              end
            end
          end)

        configs_fun_expr =
          quote do
            def unquote(configs_f_name)() do
              unquote(sorted_fun_configs)
            end
          end

        # helper
        ignore_attr_warning_expr = quote do: unquote(Helper.reg_attr(@defconfigs_key))

        are_keys_equal_expr =
          quote do
            Checker.are_keys_equal!(
              unquote(f),
              unquote(arg_names),
              unquote(raw_fun_configs)
            )
          end

        # resort expr
        [ignore_attr_warning_expr] ++ [are_keys_equal_expr] ++ funs_expr ++ [configs_fun_expr]
      end
    end
  end

  ###
  def post_match({[] = _errors, [_ | _] = new_args}, curr_m, _shared_m, _use_m, real_f_name) do
    apply(curr_m, real_f_name, Keyword.values(new_args))
  end

  def post_match({_errors, _new_args} = result, curr_m, shared_m, use_m, _real_f_name) do
    result
    |> Formatter.fmt_match_result()
    |> Formatter.fmt_errors(curr_m, shared_m, use_m)
  end

  ###
  def merge_configs(defconfigs, configs, names_key, warn) do
    quote do
      with warn <- unquote(warn),
           max_depth <- unquote(@warn_max_nested_depth),
           defconfigs <- unquote(defconfigs),
           {names, configs} <- Map.pop(unquote(configs), unquote(names_key)),
           names <- Helper.prune_names(names),
           get_nested <- Config.get_nested_config(warn, max_depth),
           get_by_names <- Config.get_configs_by_names(warn, max_depth),
           configs <- get_nested.(defconfigs, configs),
           name_configs <- get_by_names.(defconfigs, names) do
        :maps.merge(name_configs, configs)
      end
    end
  end

  def get_all_defconfigs([] = _shared_m, defconfigs_attr, _defconfigs_key) do
    quote do
      Helper.list_to_map(unquote(defconfigs_attr))
    end
  end

  def get_all_defconfigs(shared_m, defconfigs_attr, defconfigs_key) when is_atom(shared_m) do
    quote do
      shared_configs = Config.get_defconfigs(unquote(shared_m), unquote(defconfigs_key))
      defconfigs = Helper.list_to_map(unquote(defconfigs_attr))
      :maps.merge(shared_configs, defconfigs)
    end
  end

  def make_args(a_expr) do
    quote do
      keys = unquote(Helper.get_arg_names(a_expr))
      values = [unquote_splicing(a_expr)]
      Helper.make_args(keys, values, [])
    end
  end
end

defmodule Argx.Use.Defconfig do
  @moduledoc false

  alias Argx.{Const, Parser}
  alias Argx.Checker.DSL, as: Checker
  alias Argx.Use.Helper

  defmacro __using__(_opts) do
    quote do
      @defconfigs_key Const.defconfigs_key()

      defmacro defconfig(name, configs) do
        Checker.check_defconfig!(name, configs)

        name = Parser.parse_defconfig_name(name)
        configs = Parser.parse_configs(configs)
        attr = Macro.escape(%{name => configs})
        f_name = Helper.make_get_shared_configs_f_name(name, @defconfigs_key)

        operate_attr_expr =
          quote do
            unquote(Helper.reg_attr(@defconfigs_key))
            unquote(Helper.put_attr(@defconfigs_key, attr))
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

defmodule Argx.Use.Helper do
  @moduledoc false

  alias Argx.Matcher.Helper, as: MatcherHelper

  ### make function name
  def make_get_shared_configs_f_name(name, defconfigs_key) do
    make_fun_name("get#{defconfigs_key}#{name}", &fun_name_rule/1)
  end

  def make_get_fun_configs_f_name(f), do: make_fun_name("get_#{f}_configs", &fun_name_rule/1)
  def make_real_f_name(f), do: make_fun_name("real_#{f}", &fun_name_rule/1)

  defp fun_name_rule(name) when is_bitstring(name), do: ["__", name, "__"]
  defp fun_name_rule(name) when is_atom(name), do: name |> to_string() |> fun_name_rule()
  defp fun_name_rule(_), do: []

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

  ###
  def make_args(keys, values, args), do: do_make_args(keys, values, args)
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
  def list_to_map(list) when is_list(list) do
    Enum.reduce(list, %{}, fn %{} = term, map ->
      :maps.merge(map, term)
    end)
  end

  def list_to_map(other), do: other

  def make_fun_name(name, rule)
      when (is_atom(name) or is_bitstring(name)) and is_function(rule) do
    name
    |> rule.()
    |> Enum.map(fn part -> to_string(part) end)
    |> IO.iodata_to_binary()
    |> String.downcase()
    |> String.to_atom()
  end

  def make_fun_name(_other_name, _other_rule), do: nil

  ### Proxy
  def prune_names(term), do: MatcherHelper.prune_names(term)

  def sort_by_keys(keyword, keys, should_drop_flag) do
    MatcherHelper.sort_by_keys(keyword, keys, should_drop_flag)
  end
end
