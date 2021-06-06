defmodule Argx.Util do
  @moduledoc false

  ###
  def prune_names([_ | _] = names), do: Enum.map(names, fn name -> prune_names(name) end)
  def prune_names(name) when is_atom(name), do: name |> inspect() |> prune_names()
  def prune_names(":" <> name_rest), do: name_rest |> prune_names()
  def prune_names(name) when is_bitstring(name), do: String.to_atom(name)
  def prune_names(other), do: other

  ###
  def to_atom_key(map), do: AtomicMap.convert(map, %{safe: false, underscore: false})
end
