defmodule Argx.Checker do
  @moduledoc false

  @allowed_types [:list, :map, :string, :integer, :float]
  @allowed_functionalities [:optional, :auto]
  @allowed_fun_types [:def, :defp]

  def check_defconfig!(name, config) do
    check_config_name!(name)
    config |> extract_config!(true)
  end

  def check!(configs, block) do
    check_configs!(configs)
    check_fun_block!(block)
  end

  def check_configs!({:configs, _, configs}) do
    configs |> extract_config!(true)
  end

  def check_configs!(_) do
    raise "syntax error: not found configs keyword"
  end

  def check_fun_block!({:__block__, _, []}) do
    raise "with_check block is empty"
  end

  def check_fun_block!({:__block__, _, [{f_type1, _, _} | [{f_type2, _, _} | _]]})
      when f_type1 in @allowed_functionalities or f_type2 in @allowed_fun_types do
    raise "only support one function"
  end

  def check_fun_block!(_block) do
    :ok
  end

  ###
  defp extract_config!([], first?) do
    if first? do
      raise "config content is empty"
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
    raise "invalid defconfig"
  end

  defp every_config!({:__aliases__, _, _}, _) do
    :ok
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

    raise err_msg
  end

  defp every_config!([], has_type?) do
    if has_type? do
      :ok
    else
      raise "not found one of #{inspect(@allowed_types)} config items"
    end
  end

  defp every_config!(config, _) when is_atom(config) do
    :ok
  end

  ###
  defp check_config_name!({:__aliases__, _, [name]}) when is_atom(name) do
    :ok
  end

  defp check_config_name!(name) when is_atom(name) do
    :ok
  end

  defp check_config_name!(_) do
    raise "invalid defconfig name, like: :name or NameYes"
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
