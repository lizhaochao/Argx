defmodule Argx.Config do
  @moduledoc false

  @enforce_keys [:type, :optional, :auto, :range, :default, :empty, :nested]
  defstruct @enforce_keys
end

defmodule Argx.Error do
  @moduledoc false

  import Argx.Util
  alias Argx.Const

  defexception message: nil

  def reduce_errors(errors, key, path, path_handler, check_type) do
    with new_path <- path_handler.(key, path),
         new_errors <- append(new_path, errors, check_type) do
      {new_errors, nil, nil}
    end
  end

  ###
  def merge_errors(left, right) when is_list(left) and is_list(right) do
    with left_errors <- left |> pre_errors() |> Enum.sort(),
         right_errors <- right |> pre_errors() |> Enum.sort() do
      do_merger_errors([], left_errors, right_errors)
    end
  end

  defp pre_errors(errors) when is_list(errors) do
    Enum.reduce(Const.check_types(), errors, fn type, err ->
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
end
