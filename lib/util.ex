defmodule Argx.Util do
  @moduledoc false

  def list_to_map(list) when is_list(list) do
    Enum.reduce(list, %{}, fn %{} = term, map ->
      Map.merge(map, term)
    end)
  end

  def append(value, keyword, key) when is_list(keyword) do
    {_, new} =
      Keyword.get_and_update(keyword, key, fn current ->
        new_value = (current && Enum.reverse([value | Enum.reverse(current)])) || [value]
        {nil, new_value}
      end)

    new
  end

  ###
  def make_module_name([term | _] = parts) when is_atom(term) or is_bitstring(term) do
    [Elixir | parts]
    |> Enum.map(fn part -> to_string(part) end)
    |> Enum.join(".")
    |> String.to_atom()
  end

  def make_fun_name(name, rule) when is_function(rule) do
    name
    |> rule.()
    |> Enum.map(fn part -> to_string(part) end)
    |> IO.iodata_to_binary()
    |> String.downcase()
    |> String.to_atom()
  end

  ###
  def prune_names([_ | _] = names), do: Enum.map(names, fn name -> prune_names(name) end)
  def prune_names(name) when is_atom(name), do: name |> inspect() |> prune_names()
  def prune_names(":" <> name_rest), do: name_rest |> prune_names()
  def prune_names(name) when is_bitstring(name), do: String.to_atom(name)
  def prune_names(other_name), do: other_name

  def get_type(%{} = _term), do: :map
  def get_type(term) when is_bitstring(term), do: :string
  def get_type(term) when is_integer(term), do: :integer
  def get_type(term) when is_float(term), do: :float

  def get_type(term) when is_list(term) do
    term
    |> Keyword.keyword?()
    |> if(
      do: :keyword,
      else: :list
    )
  end

  def get_type(_other_term), do: :unknown

  def to_map(%{} = term), do: term
  def to_map(term) when is_list(term), do: Enum.into(term, %{})
  def to_keyword(%{} = term), do: Enum.into(term, [])
  def to_keyword(term) when is_list(term), do: term
end
