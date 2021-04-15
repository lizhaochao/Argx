defmodule Argx.Parser do
  @moduledoc false

  alias Argx.Const, as: Con

  @allowed_fun_types Con.allowed_fun_types()
  @allowed_types Con.allowed_types()
  @names_key Con.names_key()

  ###
  def parse_fun(block), do: do_parse_fun(block, %{})

  defp do_parse_fun({type, _, fun}, parts) when type in @allowed_fun_types do
    do_parse_fun(fun, parts)
  end

  defp do_parse_fun([{:when, _, fa_guard}, [{:do, block}]], parts) do
    fa_guard
    |> do_parse_fun(parts)
    |> Map.put(:block, block)
  end

  defp do_parse_fun([fa, [{:do, block}]], parts) do
    fa
    |> do_parse_fun(parts)
    |> Map.put(:block, block)
    |> Map.put(:guard, true)
  end

  defp do_parse_fun([fa, guard], parts) do
    fa
    |> do_parse_fun(parts)
    |> Map.put(:guard, guard)
  end

  defp do_parse_fun({f, _, [{_, _, nil} | _] = a}, parts) do
    parts
    |> Map.put(:f, f)
    |> Map.put(:a, a)
  end

  defp do_parse_fun({f, _, nil}, parts) do
    parts
    |> Map.put(:f, f)
    |> Map.put(:a, [])
  end

  defp do_parse_fun(_other_expr, _parts), do: nil

  ###
  def parse_configs({:configs, _, [_expr | _] = configs}) do
    do_parse_configs(configs, %{})
  end

  def parse_configs([_expr | _] = configs) do
    do_parse_configs(configs, %{})
  end

  def parse_configs(configs) do
    do_parse_configs([configs], %{})
  end

  defp do_parse_configs([], configs), do: configs

  defp do_parse_configs([{:__aliases__, _, [defconfig_name]} | rest], configs) do
    {_, new_configs} =
      Map.get_and_update(configs, @names_key, fn current ->
        new_value = (current && [defconfig_name | current]) || [defconfig_name]
        {current, new_value}
      end)

    do_parse_configs(rest, new_configs)
  end

  defp do_parse_configs([config | rest], configs) do
    config_map = every_config(config)
    new_configs = Map.merge(configs, config_map)
    do_parse_configs(rest, new_configs)
  end

  defp every_config({:||, _, [{field, _, items}, default]}) do
    do_every_config(field, items, default)
  end

  defp every_config({field, _, items}), do: do_every_config(field, items)

  defp do_every_config(field, items, default \\ nil) do
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

  defp every_item([], items), do: items

  defp every_item([type | rest], items) when type in @allowed_types do
    every_item(
      rest,
      Map.put(items, :type, type)
    )
  end

  defp every_item([:optional | rest], items) do
    every_item(
      rest,
      Map.put(items, :optional, true)
    )
  end

  defp every_item([:auto | rest], items) do
    every_item(
      rest,
      Map.put(items, :auto, true)
    )
  end

  defp every_item([{:.., _, [_, _]} = range | rest], items) do
    every_item(
      rest,
      Map.put(items, :range, range)
    )
  end

  defp every_item([range | rest], items) when is_integer(range) do
    every_item(
      rest,
      Map.put(items, :range, range)
    )
  end

  ###
  def parse_defconfig_name({:__aliases__, _, [name]}), do: name
  def parse_defconfig_name(_expr), do: raise(Argx.Error, "defconfig name should be atom")

  def parse_range(v) when is_number(v), do: [v, v]
  def parse_range({:.., _, [l, r]}), do: [l, r]
end
