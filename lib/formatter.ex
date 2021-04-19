defmodule Argx.Formatter do
  @moduledoc false

  def fmt_errors(errors, use_m, general_m, current_m) do
    cond do
      function_exported?(current_m, :fmt_errors, 1) ->
        apply(current_m, :fmt_errors, [errors])

      function_exported?(general_m, :fmt_errors, 1) ->
        apply(general_m, :fmt_errors, [errors])

      function_exported?(use_m, :fmt_errors, 1) ->
        apply(use_m, :fmt_errors, [errors])

      true ->
        default(errors)
    end
  end

  def default({:error, errors}) do
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
end
