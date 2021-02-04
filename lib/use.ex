defmodule Argx.Defconfig.Use do
  @moduledoc false

  alias Argx.Checker, as: C
  alias Argx.Const
  alias Argx.Defconfig.Use, as: Self
  alias Argx.Parser, as: P

  defmacro __using__(_opts) do
    quote do
      defmacro defconfig(name, configs) do
        C.check_defconfig!(name, configs)

        name = P.parse_defconfig_name(name)
        configs = P.parse_configs(configs)
        attr = %{name => configs} |> Macro.escape()

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

  alias Argx.Checker, as: C
  alias Argx.Const
  alias Argx.Formatter, as: F
  alias Argx.Matcher, as: M
  alias Argx.Parser, as: P
  alias Argx.Util, as: U
  alias Argx.WithCheck.Use, as: Self

  defmacro __using__(_opts) do
    quote do
      @defconfigs {:@, [], [{Const.defconfigs_key(), [], nil}]}

      defmacro with_check(configs, do: block) do
        C.check!(configs, block)

        %{
          f: f,
          a: a,
          guard: guard,
          block: block
        } = P.parse_fun(block)

        real_f_name = Self.make_real_f_name(f)
        use_m = __MODULE__

        quote do
          # ignore undefined module attribute warning
          unquote(Self.reg_attr())

          def unquote(f)(unquote_splicing(a)) when unquote(guard) do
            args = unquote(Self.make_args(a))
            configs = unquote(Self.merge_configs(configs, @defconfigs))

            __MODULE__
            |> M.match(unquote(f), args, configs)
            |> Self.post_match(unquote(use_m), __MODULE__, unquote(real_f_name))
          end

          def unquote(real_f_name)(unquote_splicing(a)) do
            unquote(block)
          end
        end
      end
    end
  end

  ###
  def post_match({:error, _} = err, use_m, current_m, _) do
    err |> F.format_errors(use_m, current_m)
  end

  def post_match([_ | _] = new_args, _, current_m, real_f_name) do
    apply(current_m, real_f_name, new_args)
  end

  ###
  def make_args(a) do
    quote do
      keys = unquote(a |> get_arg_names([]))
      values = [unquote_splicing(a)]
      keys |> Self.do_make_args(values, [])
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

  def get_arg_names([], acc) do
    acc |> Enum.reverse()
  end

  def get_arg_names([{arg, _, _} | rest], acc) do
    rest |> get_arg_names([arg | acc])
  end

  def get_arg_names([_ | rest], acc) do
    rest |> get_arg_names(acc)
  end

  ###
  def merge_configs(configs, defconfigs) do
    quote do
      {names, configs} =
        unquote(configs |> P.parse_configs() |> Macro.escape())
        |> Map.pop(unquote(Const.names_key()))

      names
      |> Self.get_configs_by_names(unquote(defconfigs))
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
  def make_real_f_name(f) do
    U.make_fun_name("real", f)
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
