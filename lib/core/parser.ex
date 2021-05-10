defmodule Argx.Parser do
  @moduledoc false

  import Argx.Util

  alias Argx.Const

  @allowed_fun_types Const.allowed_fun_types()
  @not_support_types Const.not_support_types()
  @allowed_types Const.allowed_types()
  @names_key Const.names_key()
  @configs_keyword Const.configs_keyword()

  ###
  def parse_fun({:__block__, _, [_ | _] = block}), do: parse_fun(block, [])
  def parse_fun(block), do: parse_fun([block], [])

  def parse_fun([], funs), do: Enum.reverse(funs)

  def parse_fun([expr | rest], funs) do
    fun = do_parse_fun(expr, %{})
    parse_fun(rest, [fun | funs])
  end

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

  defp do_parse_fun({f, _, [{_, _, _} | _] = a}, parts) when f not in @not_support_types do
    parts
    |> Map.put(:f, f)
    |> Map.put(:a, a)
  end

  defp do_parse_fun({f, _, _}, parts) when f not in @not_support_types do
    parts
    |> Map.put(:f, f)
    |> Map.put(:a, [])
  end

  defp do_parse_fun({type, _, [_ | _]}, _parts), do: raise(Argx.Error, "not support #{type}")
  defp do_parse_fun(_other_expr, _parts), do: raise(Argx.Error, "unknown function")

  ###
  def parse_configs({name, _, _} = configs) when name != @configs_keyword do
    do_parse_configs([configs], %{})
  end

  def parse_configs([_ | _] = configs), do: do_parse_configs(configs, %{})
  def parse_configs({@configs_keyword, _, [_ | _] = configs}), do: do_parse_configs(configs, %{})
  def parse_configs({@configs_keyword, _, []}), do: raise(Argx.Error, "configs is empty")
  def parse_configs([]), do: raise(Argx.Error, "configs is empty")

  defp do_parse_configs([], configs) do
    :maps.get(@names_key, configs, nil)
    |> is_nil()
    |> if(
      do: configs,
      else:
        (
          {_, new_configs} =
            Map.get_and_update(configs, @names_key, fn curr ->
              new_value = curr && MapSet.to_list(curr)
              {curr, new_value}
            end)

          new_configs
        )
    )
  end

  defp do_parse_configs([{:__aliases__, _, [defconfig_name]} | rest], configs)
       when is_atom(defconfig_name) do
    new_configs = reduce_defconfig_names(configs, @names_key, defconfig_name)
    do_parse_configs(rest, new_configs)
  end

  defp do_parse_configs([defconfig_name | rest], configs)
       when is_bitstring(defconfig_name) or is_atom(defconfig_name) do
    new_configs = reduce_defconfig_names(configs, @names_key, defconfig_name)
    do_parse_configs(rest, new_configs)
  end

  defp do_parse_configs([config | rest], configs) do
    config_map = every_config(config)
    new_configs = :maps.merge(configs, config_map)
    do_parse_configs(rest, new_configs)
  end

  defp reduce_defconfig_names(%{} = configs, names_key, name) do
    update = fn configs, names_key, name ->
      Map.get_and_update(configs, names_key, fn curr ->
        new_value = (curr && MapSet.put(curr, name)) || MapSet.new([name])
        {curr, new_value}
      end)
    end

    with name <- prune_names(name),
         {_, new_configs} <- update.(configs, names_key, name) do
      new_configs
    end
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
      default: default,
      empty: false,
      nested: nil
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

  defp every_item([{type, {:__aliases__, _, [nested_name]}} | rest], items)
       when type in [:list, :map] do
    with name <- prune_names(nested_name),
         items <- put_nested_name(items, type, name) do
      every_item(rest, items)
    end
  end

  defp every_item([{type, nested_name} | rest], items)
       when type in [:list, :map] and (is_bitstring(nested_name) or is_atom(nested_name)) do
    with name <- prune_names(nested_name),
         items <- put_nested_name(items, type, name) do
      every_item(rest, items)
    end
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

  defp every_item([:empty | rest], items) do
    every_item(
      rest,
      Map.put(items, :empty, true)
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

  defp every_item([other_expr | _rest], _items) do
    raise(Argx.Error, "unknown #{inspect(other_expr)}")
  end

  defp put_nested_name(items, type, nested_name) do
    items
    |> Map.put(:type, type)
    |> Map.put(:nested, nested_name)
  end

  ###
  def parse_defconfig_name(name) when is_atom(name), do: name
  def parse_defconfig_name(name) when is_bitstring(name), do: String.to_atom(name)

  def parse_defconfig_name({:__aliases__, _, [_ | _] = parts}) do
    parts
    |> Enum.map(fn part -> to_string(part) end)
    |> Enum.join("_")
    |> String.to_atom()
  end

  def parse_defconfig_name(_other), do: raise(Argx.Error, "defconfig name should be atom/string")

  ###
  def parse_range(v) when is_number(v), do: [v, v]
  def parse_range({:.., _, [l, r]}), do: [l, r]
  def parse_range(other), do: raise(Argx.Error, "not support #{inspect(other)}")
end
