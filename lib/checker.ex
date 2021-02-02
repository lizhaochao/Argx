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
  def some_type?(_, _), do: false

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

  def in_range?(_, _, _) do
    false
  end

  def are_keys_equal!(f, [_ | _] = args, %{} = configs) when is_atom(f) do
    keys1 = args |> Keyword.keys() |> Enum.sort()
    keys2 = configs |> Map.keys() |> Enum.sort()

    if keys1 == keys2 do
      :ignore
    else
      raise Argx.Error, "#{f} function has arg not config"
    end
  end

  ###
  def check_defconfig!(name, config) do
    check_config_name!(name)
    config |> extract_config!(true)
  end

  def check!(configs, block) do
    check_configs!(configs)
    check_fun_block!(block)
  end

  ###
  defp check_configs!({:configs, _, configs}) do
    configs |> extract_config!(true)
  end

  defp check_configs!(_) do
    raise Argx.Error, "syntax error: not found configs keyword"
  end

  defp check_fun_block!({:__block__, _, []}) do
    raise Argx.Error, "with_check block is empty"
  end

  defp check_fun_block!({:__block__, _, [{f_type1, _, _} | [{f_type2, _, _} | _]]})
       when f_type1 in @allowed_fun_types or f_type2 in @allowed_fun_types do
    raise Argx.Error, "only support one function"
  end

  defp check_fun_block!(_block) do
    :ok
  end

  ###
  defp extract_config!([], first?) do
    if first? do
      raise Argx.Error, "config content is empty"
    else
      :ok
    end
  end

  defp extract_config!([config | rest], _first?) do
    config |> extract_config!() |> every_config!(false)
    rest |> extract_config!(false)
  end

  defp extract_config!(config, _) do
    config |> extract_config!() |> every_config!(false)
  end

  defp extract_config!({:||, _, [{_field, _, [_ | _] = config}, _default]}) do
    config
  end

  defp extract_config!({:__aliases__, _, _} = defconfig_name) do
    defconfig_name
  end

  defp extract_config!({_field, _, [_ | _] = config}) do
    config
  end

  defp extract_config!(_) do
    raise Argx.Error, "invalid defconfig"
  end

  defp every_config!({:__aliases__, _, _} = defconfig_name, _) do
    defconfig_name |> check_config_name!()
  end

  defp every_config!([config | rest], _has_type?) when config in @allowed_types do
    rest |> every_config!(true)
  end

  defp every_config!([config | rest], has_type?) when config in @allowed_functionalities do
    rest |> every_config!(has_type?)
  end

  defp every_config!([{:.., _, [l, r]} | rest], has_type?) when is_integer(l) and is_integer(r) do
    rest |> every_config!(has_type?)
  end

  defp every_config!([value | rest], has_type?) when is_integer(value) do
    rest |> every_config!(has_type?)
  end

  defp every_config!([config | _rest], _) do
    err_msg =
      case _to_string(config) do
        :error ->
          "invalid defconfig"

        _ ->
          "unknown #{_to_string(config)} defconfig"
      end

    raise Argx.Error, err_msg
  end

  defp every_config!([], has_type?) do
    if has_type? do
      :ok
    else
      raise Argx.Error, "not found one of #{inspect(@allowed_types)} config items"
    end
  end

  defp every_config!(config, _) when is_atom(config) do
    :ok
  end

  ###
  defp check_config_name!({:__aliases__, _, [name]}) when is_atom(name) do
    :ok
  end

  defp check_config_name!(_) do
    raise Argx.Error, "invalid defconfig name, like: NameYes"
  end

  ###
  defp _to_string(value) when is_atom(value) do
    ":#{value}"
  end

  defp _to_string(value) when is_bitstring(value) do
    value
  end

  defp _to_string(_) do
    :error
  end
end