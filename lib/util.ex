defmodule Argx.Util do
  @moduledoc false

  def list_to_map(nil) do
    %{}
  end

  def list_to_map(list) do
    Enum.reduce(list, %{}, fn item, map ->
      Map.merge(map, item)
    end)
  end

  ###
  def make_fun_name(name) do
    name
    |> fun_name_rule()
    |> to_fun_name()
  end

  def make_fun_name(prefix, name) do
    name
    |> fun_name_rule(prefix)
    |> to_fun_name()
  end

  defp fun_name_rule(name) when is_bitstring(name), do: ["__", name, "__"]
  defp fun_name_rule(name) when is_atom(name), do: name |> to_string() |> fun_name_rule()
  defp fun_name_rule(_), do: []

  defp fun_name_rule(name, prefix) when is_bitstring(name) do
    ["__", prefix, "_", name, "__"]
  end

  defp fun_name_rule(name, prefix) when is_atom(name) do
    name |> to_string() |> fun_name_rule(prefix)
  end

  defp fun_name_rule(_, _) do
    []
  end

  def to_fun_name(parts) do
    parts
    |> Enum.map(fn part -> to_string(part) end)
    |> IO.iodata_to_binary()
    |> String.downcase()
    |> String.to_atom()
  end

  ###
  def make_module_name([_ | _] = parts) do
    [Elixir | parts]
    |> Enum.map(fn part -> to_string(part) end)
    |> Enum.join(".")
    |> String.to_atom()
  end

  def make_module_name(_other_parts), do: nil

  ###
  def sort_by_keys(keyword, keys) when is_list(keyword) do
    map = Enum.into(keyword, %{})
    sort_by_keys(map, keys)
  end

  def sort_by_keys(%{} = map, keys) do
    keys
    |> Enum.reduce([], fn key, item ->
      value = Map.get(map, key)
      [{key, value} | item]
    end)
    |> Enum.reverse()
  end

  def prune_names([_ | _] = names), do: Enum.map(names, fn name -> prune_names(name) end)
  def prune_names(name) when is_atom(name), do: name |> inspect() |> prune_names()
  def prune_names(":" <> name_rest), do: name_rest |> prune_names()
  def prune_names(name) when is_bitstring(name), do: String.to_atom(name)
  def prune_names(other_name), do: other_name

  ###
  def get_configs_by_names(%{} = defconfigs, [_ | _] = names) do
    names
    |> prune_names()
    |> Enum.reduce(%{}, fn name, configs ->
      defconfigs
      |> Map.fetch(name)
      |> case do
        {:ok, %{} = config} -> Map.merge(configs, config)
        :error -> raise Argx.Error, "not found config by #{name}"
      end
    end)
  end

  def get_configs_by_names(_other_defconfigs, _other_names), do: %{}
end
