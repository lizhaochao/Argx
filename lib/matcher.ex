defmodule Argx.Matcher do
  @moduledoc false

  def match(f, %{} = args, %{} = configs) when is_atom(f) do
    f |> keys_equal?(args, configs)
  end

  defp keys_equal?(f, %{} = args, %{} = configs) when is_atom(f) do
    keys1 = args |> Map.keys() |> MapSet.new()
    keys2 = configs |> Map.keys() |> MapSet.new()

    if keys1 == keys2 do
      :ignore
    else
      raise "#{f} function has arg not config"
    end
  end
end
