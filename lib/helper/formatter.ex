defmodule Argx.Formatter do
  @moduledoc false

  import Argx.Error

  ###
  def fmt_match_result({errors, new_args}, origin_type \\ nil) do
    with errors <- sort_errors(errors),
         new_args <- (origin_type && restore(origin_type, new_args)) || new_args do
      {errors, new_args}
    end
  end

  ###
  def fmt_errors({errors, new_args}, curr_m, shared_m, use_m \\ nil) do
    with f <- :fmt_errors,
         arity <- 1,
         a <- get_a(errors, new_args) do
      cond do
        module_name?(curr_m) && function_exported?(curr_m, f, arity) -> curr_m
        module_name?(shared_m) && function_exported?(shared_m, f, arity) -> shared_m
        module_name?(use_m) && function_exported?(use_m, f, arity) -> use_m
        true -> :default
      end
      |> invoke(f, a)
    end
  end

  defp invoke(:default, _f, a), do: default(a)
  defp invoke(m, f, a), do: apply(m, f, a)

  defp get_a([] = _errors, new_args), do: [new_args]
  defp get_a({:error, _} = errors, _new_args), do: [errors]

  defp default([{:error, errors}]) do
    fields_ph = "{{fields}}"

    result =
      Enum.map(errors, fn {check_type, fields} ->
        check_type
        |> case do
          :lacked -> "lacked: #{fields_ph}"
          :error_type -> "error type: #{fields_ph}"
          :out_of_range -> "out of range: #{fields_ph}"
        end
        |> String.replace(fields_ph, Enum.join(fields, ","))
      end)

    {:error, result}
  end

  defp default([new_args]), do: new_args

  ###
  def restore(:keyword, %{} = new_args), do: Keyword.new(new_args)
  def restore(:map, new_args) when is_list(new_args), do: Map.new(new_args)
  def restore(_origin_type, new_args), do: new_args

  defp module_name?(name) when not is_nil(name) and is_atom(name), do: true
  defp module_name?(_other_name), do: false
end
