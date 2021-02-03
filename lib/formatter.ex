defmodule Argx.Formatter do
  @moduledoc false

  def format_errors(errors, m) do
    if function_exported?(m, :format_errors, 1) do
      apply(m, :format_errors, [errors])
    else
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
