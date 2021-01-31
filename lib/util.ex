defmodule Argx.Util do
  @moduledoc false

  def list_to_map(nil) do
    %{}
  end

  def list_to_map(list) do
    list
    |> Enum.reduce(%{}, fn item, acc ->
      acc |> Map.merge(item)
    end)
  end

  ###
  def make_fun_name(prefix, name) do
    name
    |> fun_name_rule(prefix)
    |> IO.iodata_to_binary()
    |> String.downcase()
    |> String.to_atom()
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

  ###
  def make_module_name([_ | _] = parts) do
    [Elixir | parts]
    |> Enum.map(fn part ->
      to_string(part)
    end)
    |> Enum.join(".")
    |> String.to_atom()
  end

  ###
  def to_atom_key(%{} = data) do
    data |> traverse_map()
  end

  def to_atom_key(data) do
    data
  end

  defp traverse_map(%{} = data) when map_size(data) == 0 do
    data
  end

  defp traverse_map(%{} = data) do
    data
    |> struct_to_map()
    |> Enum.into([])
    |> do_traverse_map([])
    |> Enum.into(%{})
  end

  defp do_traverse_map([], acc) do
    acc
  end

  defp do_traverse_map([{k, v} | rest], acc) when is_list(v) do
    v2 = v |> traverse_list([])
    rest |> do_traverse_map([{string_to_atom(k), v2} | acc])
  end

  defp do_traverse_map([{k, %{} = v} | rest], acc) do
    v2 = v |> traverse_map()
    rest |> do_traverse_map([{string_to_atom(k), v2} | acc])
  end

  defp do_traverse_map([{k, v} | rest], acc) do
    rest |> do_traverse_map([{string_to_atom(k), v} | acc])
  end

  defp traverse_list([], acc) do
    acc |> Enum.reverse()
  end

  defp traverse_list([%{} = m | rest], acc) do
    m2 = m |> traverse_map()
    rest |> traverse_list([m2 | acc])
  end

  defp traverse_list([val | rest], acc) do
    rest |> traverse_list([val | acc])
  end

  defp string_to_atom(val) when is_bitstring(val) do
    val |> String.to_atom()
  end

  defp string_to_atom(val) when is_atom(val) do
    val
  end

  defp struct_to_map(struct) do
    struct |> Map.drop([:__meta__, :__struct__])
  end
end
