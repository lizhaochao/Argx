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

  def get_all_by_names([_ | _] = names, %{} = all) do
    names
    |> Enum.reduce(%{}, fn name, acc ->
      config = all |> Map.get(name, nil)
      (config && acc |> Map.merge(config)) || acc
    end)
  end

  def get_all_by_names(_, _) do
    %{}
  end
end
