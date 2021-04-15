defmodule Argx.Checker do
  @moduledoc false

  @allowed_types [:list, :map, :string, :integer, :float]
  @allowed_functionalities [:optional, :auto]
  @allowed_fun_types [:def, :defp]

  ###
  def some_type?(v, :integer), do: is_integer(v)
  def some_type?(v, :float), do: is_float(v)
  def some_type?(v, :string), do: is_bitstring(v)
  def some_type?(v, :list), do: is_list(v)
  def some_type?(v, :map), do: is_map(v)
  def some_type?(_v, _other_type), do: false

  def in_range?(v, [l, r], :integer) when is_integer(v) do
    (v > l and v < r) or (v == l and v == r)
  end

  def in_range?(v, [l, r], :float) when is_float(v) do
    (v > l and v < r) or (v == l and v == r)
  end

  def in_range?(v, [l, r], :string) when is_bitstring(v) do
    len = String.length(v)
    (len > l and len < r) or (len == l and len == r)
  end

  def in_range?(v, [l, r], :list) when is_list(v) do
    len = length(v)
    (len > l and len < r) or (len == l and len == r)
  end

  def in_range?(v, [l, r], :map) when is_map(v) do
    len = map_size(v)
    (len > l and len < r) or (len == l and len == r)
  end

  def in_range?(_v, _range, _other_type), do: false

  def are_keys_equal!(
        f_name,
        [{_arg_name, _arg_value} | _] = args,
        %{} = configs
      )
      when is_atom(f_name) do
    keys1 = args |> Keyword.keys() |> Enum.sort()
    keys2 = configs |> Map.keys() |> Enum.sort()

    keys1
    |> Kernel.==(keys2)
    |> if(
      do: :ignore,
      else: raise(Argx.Error, "#{f_name} function has arg not config")
    )
  end

  ###
  def check_defconfig!(name, config) do
    check_config_name!(name)
    extract_config!(config, true)
  end

  def check!(configs, block) do
    check_configs!(configs)
    check_fun_block!(block)
  end

  ###
  defp check_configs!({:configs, _, configs}), do: extract_config!(configs, true)
  defp check_configs!(_other_expr), do: raise(Argx.Error, "not found configs keyword")

  defp check_fun_block!({:__block__, _, []}), do: raise(Argx.Error, "with_check block is empty")

  defp check_fun_block!({:__block__, _, [{f_type1, _, _} | [{f_type2, _, _} | _]]})
       when f_type1 in @allowed_fun_types or f_type2 in @allowed_fun_types do
    raise Argx.Error, "only support one function"
  end

  defp check_fun_block!(_block), do: :ok

  ###
  defp extract_config!([], first?) do
    first?
    |> if(
      do: raise(Argx.Error, "config content is empty"),
      else: :ok
    )
  end

  defp extract_config!([config | rest], _first?) do
    config |> extract_config!() |> every_config!(false)
    extract_config!(rest, false)
  end

  defp extract_config!(config, _first?) do
    config |> extract_config!() |> every_config!(false)
  end

  defp extract_config!({:||, _, [{_field, _, [_ | _] = config}, _default]}), do: config
  defp extract_config!({:__aliases__, _, _} = defconfig_name), do: defconfig_name
  defp extract_config!({_field, _, [_ | _] = config}), do: config
  defp extract_config!(_other_expr), do: raise(Argx.Error, "invalid defconfig")

  defp every_config!({:__aliases__, _, _} = defconfig_name, _) do
    check_config_name!(defconfig_name)
  end

  defp every_config!([config | rest], _has_type?) when config in @allowed_types do
    every_config!(rest, true)
  end

  defp every_config!([config | rest], has_type?) when config in @allowed_functionalities do
    every_config!(rest, has_type?)
  end

  defp every_config!([{:.., _, [l, r]} | rest], has_type?) when is_integer(l) and is_integer(r) do
    every_config!(rest, has_type?)
  end

  defp every_config!([value | rest], has_type?) when is_integer(value) do
    every_config!(rest, has_type?)
  end

  defp every_config!([config | _rest], _has_type?) do
    err_msg =
      config
      |> _to_string()
      |> case do
        :error ->
          "invalid defconfig"

        _ ->
          "unknown #{_to_string(config)} defconfig"
      end

    raise Argx.Error, err_msg
  end

  defp every_config!([], has_type?) do
    has_type?
    |> if(
      do: :ok,
      else: raise(Argx.Error, "not found one of #{inspect(@allowed_types)} config items")
    )
  end

  defp every_config!(config, _has_type?) when is_atom(config), do: :ok

  ###
  defp check_config_name!({:__aliases__, _, [name]}) when is_atom(name), do: :ok
  defp check_config_name!(_other_expr), do: raise(Argx.Error, "invalid defconfig name")

  ###
  defp _to_string(v) when is_atom(v), do: ":#{v}"
  defp _to_string(v) when is_bitstring(v), do: v
  defp _to_string(_), do: :error
end
