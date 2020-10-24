defmodule Parser do
  @moduledoc false

  def read do
    nil
  end

  def parse do
    # TODO: parse yaml done, then generate every path to result key, default is false
    nil
  end

  # ---
  def parse_result(%{} = result, :simple) when result |> map_size == 0 do
    false
  end

  def parse_result(result, :simple) do
    result[:result]
    |> Enum.map(fn {_, [result]} ->
      result
    end)
    |> Enum.all?()
  end
end
