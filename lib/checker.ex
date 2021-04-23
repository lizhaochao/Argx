defmodule Argx.Checker do
  @moduledoc false

  alias Argx.Const

  @allowed_fun_types Const.allowed_fun_types()
  @configs_keyword Const.configs_keyword()

  ### Argx
  def check_args!(%{} = _args), do: :ignore

  def check_args!(args) when is_list(args) do
    args
    |> Keyword.keyword?()
    |> if(
      do: :ignore,
      else: raise(Argx.Error, "args must be map or keyword")
    )
  end

  def check_args!(_other_args), do: raise(Argx.Error, "args must be map or keyword")

  def check_config_names!(config_names) do
    case config_names do
      [_ | _] -> :ignore
      _ -> raise Argx.Error, "config names must be list & not empty"
    end
  end

  ### with check macro
  def check!(configs, block) do
    with :ok <- check_configs(configs),
         :ok = ok <- check_block(block) do
      ok
    else
      :configs_error -> raise Argx.Error, "not found #{@configs_keyword} keyword"
      :block_error -> raise Argx.Error, "unknown function type"
      :block_empty_error -> raise Argx.Error, "required one function at least"
      _ -> :ok
    end
  end

  defp check_configs({configs_keyword, _, _}) when configs_keyword == @configs_keyword, do: :ok
  defp check_configs(_), do: :configs_error

  defp check_block({:__block__, _, [expr | _]}), do: check_block(expr)
  defp check_block({fun_type, _, _}) when fun_type in @allowed_fun_types, do: :ok
  defp check_block({:__block__, [], []}), do: :block_empty_error
  defp check_block(_), do: :block_error

  ### defconfig macro
  def check_defconfig!(_name, [_ | _] = configs), do: check_defconfig!(configs)
  def check_defconfig!(_name, {_, _, _} = config), do: check_defconfig!([config])
  def check_defconfig!(_name, []), do: raise(Argx.Error, "configs is empty")

  def check_defconfig!([{:||, _, [{_, _, _} = config, _]} | _]), do: check_defconfig!(config)
  def check_defconfig!([{_, _, _} = config | _]), do: check_defconfig!(config)
  def check_defconfig!({_, _, [_ | _]}), do: :ok
  def check_defconfig!({_, _, []}), do: raise(Argx.Error, "at least config type")

  ###
  def some_type?(v, :integer), do: is_integer(v)
  def some_type?(v, :float), do: is_float(v)
  def some_type?(v, :string), do: is_bitstring(v)
  def some_type?(v, :list), do: is_list(v)
  def some_type?(v, :map), do: is_map(v)
  def some_type?(v, :boolean), do: is_boolean(v)
  def some_type?(_other_v, _other_type), do: false

  def in_range?(v, [l, r], :integer) when is_integer(v) do
    (v >= l and v <= r) or (v == l and v == r)
  end

  def in_range?(v, [l, r], :float) when is_float(v) do
    (v >= l and v <= r) or (v == l and v == r)
  end

  def in_range?(v, [l, r], :string) when is_bitstring(v) do
    len = String.length(v)
    (len >= l and len <= r) or (len == l and len == r)
  end

  def in_range?(v, [l, r], :list) when is_list(v) do
    len = length(v)
    (len >= l and len <= r) or (len == l and len == r)
  end

  def in_range?(v, [l, r], :map) when is_map(v) do
    len = map_size(v)
    (len >= l and len <= r) or (len == l and len == r)
  end

  def in_range?(v, [_l, _r], :boolean) when is_boolean(v) do
    true
  end

  def in_range?(_other_v, _range, _other_type), do: false

  def empty?(0, :integer), do: true
  def empty?(0.0, :float), do: true
  def empty?("", :string), do: true
  def empty?([], :list), do: true
  def empty?(%{} = v, :map), do: Enum.empty?(v)
  def empty?(_other_v, _other_type), do: false

  def are_keys_equal!(
        f_name,
        arg_names,
        configs
      )
      when is_atom(f_name) and is_list(arg_names) and is_list(configs) do
    arg_names2 = Keyword.keys(configs)

    arg_names
    |> Kernel.==(arg_names2)
    |> if(
      do: :ok,
      else:
        (
          diff_names = (arg_names -- arg_names2) ++ (arg_names2 -- arg_names)
          msg = "
          >> #{f_name} function:
          >> there are some args that not found configs.
          >> have a try to check #{inspect(diff_names)} args."

          raise Argx.Error, msg
        )
    )
  end

  def are_keys_equal!(_f_name, _arg_names, _configs), do: raise(Argx.Error, "data type error")
end
