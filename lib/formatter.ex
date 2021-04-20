defmodule Argx.Formatter do
  @moduledoc false

  def fmt_errors(errors, use_m, general_m, current_m) do
    f_name = :fmt_errors
    arity = 1

    cond do
      module_name?(current_m) && function_exported?(current_m, f_name, arity) ->
        apply(current_m, f_name, [errors])

      module_name?(general_m) && function_exported?(general_m, f_name, arity) ->
        apply(general_m, f_name, [errors])

      module_name?(use_m) && function_exported?(use_m, f_name, arity) ->
        apply(use_m, f_name, [errors])

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

  defp module_name?(name) when is_atom(name), do: true
  defp module_name?(_other_name), do: false
end
