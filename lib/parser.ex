defmodule Argx.Parser do
  @moduledoc false

  alias Argx.Const, as: Con

  @allowed_fun_types Con.allowed_fun_types()
  @allowed_types Con.allowed_types()
  @names_key Con.names_key()

  ###
  def parse_fun(block) do
    block |> _parse_fun(%{})
  end

  defp _parse_fun({type, _, fun}, acc) when type in @allowed_fun_types do
    fun |> _parse_fun(acc)
  end

  defp _parse_fun([{:when, _, fa_guard}, [{:do, block}]], acc) do
    fa_guard
    |> _parse_fun(acc)
    |> Map.put(:block, block)
  end

  defp _parse_fun([fa, [{:do, block}]], acc) do
    fa
    |> _parse_fun(acc)
    |> Map.put(:block, block)
    |> Map.put(:guard, true)
  end

  defp _parse_fun([fa, guard], acc) do
    fa
    |> _parse_fun(acc)
    |> Map.put(:guard, guard)
  end

  defp _parse_fun({f, _, [{_, _, nil} | _] = a}, acc) do
    acc
    |> Map.put(:f, f)
    |> Map.put(:a, a)
  end

  defp _parse_fun({f, _, nil}, acc) do
    acc
    |> Map.put(:f, f)
    |> Map.put(:a, [])
  end

  defp _parse_fun(_, _) do
    nil
  end

  ###
  def parse_configs({:configs, _, [_ | _] = configs}) do
    configs |> _parse_configs(%{})
  end

  def parse_configs([_ | _] = configs) do
    configs |> _parse_configs(%{})
  end

  def parse_configs(configs) do
    [configs] |> _parse_configs(%{})
  end

  def _parse_configs([], acc) do
    acc
  end

  def _parse_configs([{:__aliases__, _, [defconfig_name]} | rest], acc) do
    {_, acc} =
      Map.get_and_update(acc, @names_key, fn current ->
        new_value = (current && [defconfig_name | current]) || [defconfig_name]
        {current, new_value}
      end)

    rest |> _parse_configs(acc)
  end

  def _parse_configs([config | rest], acc) do
    config_map = config |> every_config()
    acc = acc |> Map.merge(config_map)
    rest |> _parse_configs(acc)
  end

  defp every_config({:||, _, [{field, _, items}, default]}) do
    _every_config(field, items, default)
  end

  defp every_config({field, _, items}) do
    _every_config(field, items)
  end

  defp _every_config(field, items, default \\ nil) do
    config = %Argx.Config{
      auto: false,
      optional: false,
      type: nil,
      range: nil,
      default: default
    }

    items = every_item(items, config)
    Map.put(%{}, field, items)
  end

  defp every_item([], acc) do
    acc
  end

  defp every_item([type | rest], acc) when type in @allowed_types do
    acc = Map.put(acc, :type, type)
    rest |> every_item(acc)
  end

  defp every_item([:optional | rest], acc) do
    acc = Map.put(acc, :optional, true)
    rest |> every_item(acc)
  end

  defp every_item([:auto | rest], acc) do
    acc = Map.put(acc, :auto, true)
    rest |> every_item(acc)
  end

  defp every_item([{:.., _, [_, _]} = range | rest], acc) do
    acc = Map.put(acc, :range, range)
    rest |> every_item(acc)
  end

  defp every_item([range | rest], acc) when is_integer(range) do
    acc = Map.put(acc, :range, range)
    rest |> every_item(acc)
  end

  ###
  def parse_defconfig_name({:__aliases__, _, [name]}) do
    name
  end

  def parse_defconfig_name(_) do
    :ignore
  end
end
