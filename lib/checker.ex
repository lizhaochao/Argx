defmodule Argx.Checker do
  @moduledoc false

  alias Argx.Const

  @allowed_fun_types Const.allowed_fun_types()
  @configs_keyword Const.configs_keyword()

  ###
  def check!(configs, block) do
    with :ok <- check_configs(configs),
         :ok <- check_block(block) do
      :ok
    else
      :configs_error -> raise Argx.Error, "not found #{@configs_keyword} keyword"
      :block_error -> raise Argx.Error, "unknown function type"
      _ -> :ok
    end
  end

  defp check_configs({configs_keyword, _, _}) when configs_keyword == @configs_keyword, do: :ok
  defp check_configs(_), do: :configs_error

  defp check_block({fun_type, _, _}) when fun_type in @allowed_fun_types, do: :ok
  defp check_block(_), do: :block_error

  ###
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
  def some_type?(_v, _other_type), do: false

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

  def in_range?(_v, _range, _other_type), do: false

  def are_keys_equal!(
        f_name,
        [{_arg_name, _arg_value} | _] = args,
        %{} = configs
      )
      when is_atom(f_name) do
    arg_keys = args |> Keyword.keys() |> Enum.sort()
    config_keys = configs |> Map.keys() |> Enum.sort()

    arg_keys
    |> Kernel.==(config_keys)
    |> if(
      do: :ok,
      else: raise(Argx.Error, "#{f_name} function has arg not config")
    )
  end
end
