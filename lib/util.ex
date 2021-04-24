defmodule Argx.Util do
  @moduledoc false

  def list_to_map(list) when is_list(list) do
    Enum.reduce(list, %{}, fn term, map ->
      Map.merge(map, term)
    end)
  end

  def append(value, keyword, key) when is_list(keyword) do
    {_, new_keyword} =
      Keyword.get_and_update(keyword, key, fn current ->
        new_value = (current && Enum.reverse([value | Enum.reverse(current)])) || [value]
        {nil, new_value}
      end)

    new_keyword
  end

  ###
  def make_module_name([_ | _] = parts) do
    [Elixir | parts]
    |> Enum.map(fn part -> to_string(part) end)
    |> Enum.join(".")
    |> String.to_atom()
  end

  def make_module_name(_other_parts), do: nil

  def make_fun_name(name) do
    name
    |> fun_name_rule()
    |> Enum.map(fn part -> to_string(part) end)
    |> IO.iodata_to_binary()
    |> String.downcase()
    |> String.to_atom()
  end

  defp fun_name_rule(name) when is_bitstring(name), do: ["__", name, "__"]
  defp fun_name_rule(name) when is_atom(name), do: name |> to_string() |> fun_name_rule()
  defp fun_name_rule(_), do: []

  ###
  def sort_by_keys(keyword, keys) when is_list(keyword) do
    sort_by_keys(to_map(keyword), keys)
  end

  def sort_by_keys(%{} = map, keys) do
    keys
    |> Enum.reduce([], fn key, keyword ->
      value = Map.get(map, key)
      [{key, value} | keyword]
    end)
    |> Enum.reverse()
  end

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

  def restore(:keyword, %{} = new_args), do: Enum.into(new_args, [])
  def restore(:map, new_args) when is_list(new_args), do: Enum.into(new_args, %{})
  def restore(_origin_type, new_args), do: new_args

  def to_map(%{} = term), do: term
  def to_map(term) when is_list(term), do: Enum.into(term, %{})
  def to_keyword(%{} = term), do: Enum.into(term, [])
  def to_keyword(term) when is_list(term), do: term
end
