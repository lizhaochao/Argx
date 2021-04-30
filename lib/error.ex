defmodule Argx.Error do
  @moduledoc false

  defexception message: nil

  def reduce_errors(errors, [_ | _] = keys, path, path_handler, check_type) do
    Enum.reduce(keys, errors, fn arg_name, errors ->
      {errors, _, _} = reduce_errors(errors, arg_name, path, path_handler, check_type)
      errors
    end)
  end

  def reduce_errors(errors, key, path, path_handler, check_type)
      when is_atom(key) or is_bitstring(key) do
    with new_path <- path_handler.(key, path),
         new_errors <- append(new_path, errors, check_type) do
      {new_errors, nil, nil}
    end
  end

  def reduce_errors(errors, _other_keys, _path, _path_handler, _check_type), do: errors

  ###
  def merge_errors(left, right, check_types) when is_list(left) and is_list(right) do
    with left_errors <- left |> pre_errors(check_types) |> Enum.sort(),
         right_errors <- right |> pre_errors(check_types) |> Enum.sort() do
      do_merger_errors([], left_errors, right_errors)
    end
  end

  defp pre_errors(errors, check_types) when is_list(errors) do
    Enum.reduce(check_types, errors, fn type, err ->
      {_, new} =
        Keyword.get_and_update(err, type, fn current ->
          {nil, current || []}
        end)

      new
    end)
  end

  defp do_merger_errors(new_errors, [] = _left, [] = _right), do: Enum.reverse(new_errors)

  defp do_merger_errors(
         new_errors,
         [{l_type, l_value} | l_rest],
         [{r_type, r_value} | r_rest]
       )
       when l_type == r_type do
    value =
      case {l_value, r_value} do
        {[], []} -> nil
        {[], [_ | _]} -> r_value
        {[_ | _], []} -> l_value
        {[_ | _], [_ | _]} -> l_value ++ r_value
      end

    value
    |> Kernel.&&([{l_type, Enum.sort(value)} | new_errors])
    |> Kernel.||(new_errors)
    |> do_merger_errors(l_rest, r_rest)
  end

  ###
  def sort_errors([_ | _] = errors) do
    sorted_errors =
      errors
      |> Enum.sort()
      |> Enum.map(fn {type, fields} ->
        {type, Enum.sort(fields)}
      end)

    {:error, sorted_errors}
  end

  def sort_errors({:error, errors}), do: sort_errors(errors)
  def sort_errors([] = errors), do: errors

  ###
  def append(value, keyword, key) when is_list(keyword) and is_atom(key) do
    {_, new} =
      Keyword.get_and_update(keyword, key, fn current ->
        new_value = (current && Enum.reverse([value | Enum.reverse(current)])) || [value]
        {nil, new_value}
      end)

    new
  end

  def append(_value, _other_keyword, _other_key), do: []
end
