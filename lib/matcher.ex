defmodule Argx.Matcher do
  @moduledoc false

  alias Argx.{Checker, Converter, Defaulter, Formatter, Parser, Util}

  def argx_match(args, config_names, current_m, general_m, get_configs) do
    Checker.check_args!(args)
    Checker.check_config_names!(config_names)

    configs = get_configs.(general_m, current_m, config_names) |> Enum.into([])
    new_args = Util.sort_by_keys(args, Keyword.keys(configs))
    origin_type = Util.get_type(args)

    current_m
    |> match(new_args, configs)
    |> Formatter.fmt_match_result(origin_type)
    |> Formatter.fmt_errors(current_m, general_m)
  end

  ###
  def match(m, [{_arg_name, _arg_value} | _] = args, [_ | _] = configs) when is_atom(m) do
    new_args =
      args
      |> Defaulter.set_default(configs, m)
      |> Converter.convert(configs)

    {[], new_args, configs}
    |> lacked()
    |> drop_checked_keys(new_args, configs)
    |> error_type()
    |> drop_checked_keys(new_args, configs)
    |> out_of_range()
    |> output_result(new_args)
  end

  def match(_, _, _), do: :match_error

  ###
  def lacked({errors, args, configs}), do: do_lacked(errors, args, configs)

  defp do_lacked([], [], []), do: []

  defp do_lacked(errors, [], []), do: {:error, errors}

  defp do_lacked(
         errors,
         [{arg_name, nil} | arg_rest],
         [{arg_name2, %Argx.Config{optional: false}} | config_rest]
       )
       when arg_name == arg_name2 do
    errors
    |> reduce_errors(:lacked, arg_name)
    |> do_lacked(arg_rest, config_rest)
  end

  defp do_lacked(
         errors,
         [{arg_name, arg_value} | arg_rest],
         [{arg_name2, %Argx.Config{optional: false, type: type, empty: true}} | config_rest]
       )
       when arg_name == arg_name2 do
    arg_value
    |> Checker.empty?(type)
    |> if(
      do: reduce_errors(errors, :lacked, arg_name),
      else: errors
    )
    |> do_lacked(arg_rest, config_rest)
  end

  defp do_lacked(
         errors,
         [{arg_name, _} | arg_rest],
         [{arg_name2, _} | config_rest]
       )
       when arg_name == arg_name2 do
    do_lacked(errors, arg_rest, config_rest)
  end

  ###
  def error_type({errors, args, configs}), do: do_error_type(errors, args, configs)

  defp do_error_type([], [], []), do: []

  defp do_error_type(errors, [], []), do: {:error, errors}

  defp do_error_type(
         errors,
         [{arg_name, nil} | arg_rest],
         [{arg_name2, %Argx.Config{optional: true}} | config_rest]
       )
       when arg_name == arg_name2 do
    do_error_type(errors, arg_rest, config_rest)
  end

  defp do_error_type(
         errors,
         [{arg_name, arg_value} | arg_rest],
         [{arg_name2, %Argx.Config{type: type}} | config_rest]
       )
       when arg_name == arg_name2 do
    arg_value
    |> Checker.some_type?(type)
    |> if(
      do: errors,
      else: reduce_errors(errors, :error_type, arg_name)
    )
    |> do_error_type(arg_rest, config_rest)
  end

  ###
  def out_of_range({errors, args, configs}), do: do_out_of_range(errors, args, configs)

  defp do_out_of_range([], [], []), do: []

  defp do_out_of_range(errors, [], []), do: {:error, errors}

  defp do_out_of_range(
         errors,
         [{arg_name, nil} | arg_rest],
         [{arg_name2, %Argx.Config{optional: true}} | config_rest]
       )
       when arg_name == arg_name2 do
    do_out_of_range(errors, arg_rest, config_rest)
  end

  defp do_out_of_range(
         errors,
         [{arg_name, _} | arg_rest],
         [{arg_name2, %Argx.Config{range: nil}} | config_rest]
       )
       when arg_name == arg_name2 do
    do_out_of_range(errors, arg_rest, config_rest)
  end

  defp do_out_of_range(
         errors,
         [{arg_name, arg_value} | arg_rest],
         [{arg_name2, %Argx.Config{type: type, range: range}} | config_rest]
       )
       when arg_name == arg_name2 do
    arg_value
    |> Checker.in_range?(Parser.parse_range(range), type)
    |> if(
      do: errors,
      else: reduce_errors(errors, :out_of_range, arg_name)
    )
    |> do_out_of_range(arg_rest, config_rest)
  end

  ###
  defp reduce_errors(errors, check_type, field) do
    {nil, new_errors} =
      Keyword.get_and_update(errors, check_type, fn current ->
        new_value = (current && [field | current]) || [field]
        {nil, new_value}
      end)

    new_errors
  end

  def drop_checked_keys([], args, configs), do: {[], args, configs}

  def drop_checked_keys({:error, errors}, args, configs) do
    drop_checked_keys(errors, errors, args, configs)
  end

  defp drop_checked_keys([], errors, args, configs), do: {errors, args, configs}

  defp drop_checked_keys([{_check_type, keys} | rest], errors, args, configs) do
    args = Keyword.drop(args, keys)
    configs = Keyword.drop(configs, keys)
    drop_checked_keys(rest, errors, args, configs)
  end

  def output_result(errors, new_args), do: {errors, new_args}
end
