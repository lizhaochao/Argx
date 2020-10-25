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
    |> Enum.flat_map(fn {k, v} ->
      []
      |> Keyword.put(k, v |> do_m_to_kw())
    end)
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
      |> Enum.flat_map(fn {k, v} ->
        []
        |> Keyword.put(k, v |> do_m_to_kw())
      end)

    remain |> do_m_to_kw(acc ++ [result])
  end

  def do_m_to_kw([], acc) do
    acc
  end
end
