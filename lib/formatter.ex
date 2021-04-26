defmodule Argx.Formatter do
  @moduledoc false

  ###
  def fmt_match_result({errors, new_args}, origin_type \\ nil) do
    errors = sort_errors(errors)
    new_args = (origin_type && restore(origin_type, new_args)) || new_args
    {errors, new_args}
  end

  ###
  def fmt_errors({errors, new_args}, curr_m, general_m, use_m \\ nil) do
    f = :fmt_errors
    arity = 1

    a =
      case errors do
        [] -> [new_args]
        {:error, _} -> [errors]
      end

    cond do
      module_name?(curr_m) && function_exported?(curr_m, f, arity) ->
        apply(curr_m, f, a)

      module_name?(general_m) && function_exported?(general_m, f, arity) ->
        apply(general_m, f, a)

      module_name?(use_m) && function_exported?(use_m, f, arity) ->
        apply(use_m, f, a)

      true ->
        default(errors)
    end
  end

  defp default({:error, errors}) do
    fields_ph = "{{fields}}"

    result =
      Enum.map(errors, fn {check_type, fields} ->
        check_type
        |> case do
          :lacked ->
            "lacked: #{fields_ph}"

          :error_type ->
            "error type: #{fields_ph}"

          :out_of_range ->
            "out of range: #{fields_ph}"
        end
        |> String.replace(fields_ph, Enum.join(fields, ","))
      end)

    {:error, result}
  end

  defp default(new_args), do: new_args

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
  def sort_errors(_other_errors), do: raise(Argx.Error, "reverse errors error")

  def restore(:keyword, %{} = new_args), do: Enum.into(new_args, [])
  def restore(:map, new_args) when is_list(new_args), do: Enum.into(new_args, %{})
  def restore(_origin_type, new_args), do: new_args

  defp module_name?(name) when is_atom(name), do: true
  defp module_name?(_other_name), do: false
end
