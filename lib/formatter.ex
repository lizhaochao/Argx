defmodule Argx.Formatter do
  @moduledoc false

  def format_errors(errors, use_m, current_m) do
    cond do
      function_exported?(current_m, :format_errors, 1) ->
        apply(current_m, :format_errors, [errors])

      function_exported?(use_m, :format_errors, 1) ->
        apply(use_m, :format_errors, [errors])

      true ->
        default(errors)
    end
  end

  def default({:error, errors}) do
    fields_ph = "{{fields}}"

    result =
      errors
      |> Enum.map(fn {check_type, fields} ->
        case check_type do
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
