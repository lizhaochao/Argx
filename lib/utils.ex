defmodule Utils do
  @moduledoc false

  def m_to_kw(m) when m |> is_map() do
    m |> do_m_to_kw()
  end

  def m_to_kw(_) do
    raise ArgumentError, message: "only support map at present"
  end

  def do_m_to_kw(%{} = m) do
    m
    |> Enum.map(fn {k, v} ->
      []
      |> Keyword.put(k, v |> do_m_to_kw())
    end)
    |> get_head()
  end

  def do_m_to_kw(v) when v |> is_bitstring() do
    v
  end

  def do_m_to_kw([_ | _] = keyword) do
    keyword |> do_m_to_kw([])
  end

  def do_m_to_kw([item | remain], acc) do
    result =
      item
      |> Enum.map(fn {k, v} ->
        []
        |> Keyword.put(k, v |> do_m_to_kw())
      end)
      |> get_head()

    remain |> do_m_to_kw(acc ++ [result])
  end

  def do_m_to_kw([], acc) do
    acc
  end

  # -
  defp get_head(list) when list |> length() > 0 do
    list |> hd()
  end

  defp get_head(data) do
    data
  end
end
