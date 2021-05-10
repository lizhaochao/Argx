defmodule Argx.Util do
  @moduledoc false

  ###
  def prune_names([_ | _] = names), do: Enum.map(names, fn name -> prune_names(name) end)
  def prune_names(name) when is_atom(name), do: name |> inspect() |> prune_names()
  def prune_names(":" <> name_rest), do: name_rest |> prune_names()
  def prune_names(name) when is_bitstring(name), do: String.to_atom(name)
  def prune_names(other), do: other

  ###
  def to_atom_key(%_{} = map), do: map |> struct_to_map() |> to_atom_key()
  def to_atom_key(%{} = map), do: traverse_map(map)
  def to_atom_key(other), do: other

  defp traverse_map(%{} = map) when map_size(map) == 0, do: map
  defp traverse_map(%{} = map), do: map |> Enum.into([]) |> do_traverse_map([])

  defp do_traverse_map([], new_map), do: Map.new(new_map)

  defp do_traverse_map([{k, v} | rest], new_map) when is_list(v) do
    new_v = traverse_list(v, [])
    do_traverse_map(rest, [{string_to_atom(k), new_v} | new_map])
  end

  defp do_traverse_map([{k, %{} = v} | rest], new_map) do
    new_v = traverse_map(v)
    do_traverse_map(rest, [{string_to_atom(k), new_v} | new_map])
  end

  defp do_traverse_map([{k, v} | rest], new_map) do
    do_traverse_map(rest, [{string_to_atom(k), v} | new_map])
  end

  defp traverse_list([], new_list), do: Enum.reverse(new_list)

  defp traverse_list([%{} = m | rest], new_list) do
    new_m = traverse_map(m)
    traverse_list(rest, [new_m | new_list])
  end

  defp traverse_list([term | rest], new_list), do: traverse_list(rest, [term | new_list])

  defp string_to_atom(term) when is_bitstring(term), do: String.to_atom(term)
  defp string_to_atom(term) when is_atom(term), do: term

  defp struct_to_map(%_{} = struct), do: Map.drop(struct, [:__meta__, :__struct__])
  defp struct_to_map(other), do: other
end
