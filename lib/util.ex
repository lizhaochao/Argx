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
  def make_fun_name(prefix, name) do
    name
    |> fun_name_rule(prefix)
    |> to_fun_name()
  end

  defp fun_name_rule(name, prefix) when is_bitstring(name) do
    [prefix, "_", name, "__", "macro"]
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

  ###
  def sort_by_keys(keys, %{} = map) do
    keys
    |> Enum.reduce([], fn key, item ->
      value = Map.get(map, key)
      [{key, value} | item]
    end)
    |> Enum.reverse()
  end
end
