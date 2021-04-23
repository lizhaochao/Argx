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

    []
    |> traverse(new_args, configs)
    |> output_result(new_args)
  end

  def match(_, _, _), do: :match_error

  ###
  def traverse(errors, [], []), do: errors

  def traverse(
        errors,
        [{_arg_name, _arg_value} = arg | new_args_rest],
        [{_arg_name2, %Argx.Config{}} = config | configs_rest]
      ) do
    new_errors =
      errors
      |> lacked(arg, config)
      |> error_type()
      |> out_of_range()

    traverse(new_errors, new_args_rest, configs_rest)
  end

  ###
  def lacked(
        errors,
        {arg_name, nil},
        {arg_name2, %Argx.Config{optional: false}}
      )
      when arg_name == arg_name2 do
    reduce_errors(errors, arg_name, :lacked)
  end

  def lacked(
        errors,
        {arg_name, arg_value} = arg,
        {arg_name2, %Argx.Config{optional: false, type: type, empty: true}} = config
      )
      when arg_name == arg_name2 do
    if Checker.empty?(arg_value, type) do
      reduce_errors(errors, arg_name, :lacked)
    else
      {errors, arg, config}
    end
  end

  def lacked(
        errors,
        {arg_name, _} = arg,
        {arg_name2, _} = config
      )
      when arg_name == arg_name2 do
    {errors, arg, config}
  end

  ###
  def error_type({errors, nil, nil}), do: {errors, nil, nil}
  def error_type({errors, args, configs}), do: error_type(errors, args, configs)

  defp error_type(
         errors,
         {arg_name, nil},
         {arg_name2, %Argx.Config{optional: true}}
       )
       when arg_name == arg_name2 do
    {errors, nil, nil}
  end

  defp error_type(
         errors,
         {arg_name, arg_value} = arg,
         {arg_name2, %Argx.Config{type: type}} = config
       )
       when arg_name == arg_name2 do
    if Checker.some_type?(arg_value, type) do
      {errors, arg, config}
    else
      reduce_errors(errors, arg_name, :error_type)
    end
  end

  ###
  def out_of_range({errors, nil, nil}), do: errors
  def out_of_range({errors, args, configs}), do: out_of_range(errors, args, configs)

  defp out_of_range(
         errors,
         {arg_name, nil},
         {arg_name2, %Argx.Config{optional: true}}
       )
       when arg_name == arg_name2 do
    errors
  end

  defp out_of_range(
         errors,
         {arg_name, _},
         {arg_name2, %Argx.Config{range: nil}}
       )
       when arg_name == arg_name2 do
    errors
  end

  defp out_of_range(
         errors,
         {arg_name, arg_value},
         {arg_name2, %Argx.Config{type: type, range: range}}
       )
       when arg_name == arg_name2 do
    if Checker.in_range?(arg_value, Parser.parse_range(range), type) do
      errors
    else
      errors
      |> reduce_errors(arg_name, :out_of_range)
      |> out_of_range()
    end
  end

  ###
  defp reduce_errors(errors, field, check_type) do
    {nil, new_errors} =
      Keyword.get_and_update(errors, check_type, fn current ->
        new_value = (current && [field | current]) || [field]
        {nil, new_value}
      end)

    {new_errors, nil, nil}
  end

  def output_result([], new_args), do: {[], new_args}
  def output_result(errors, new_args), do: {{:error, errors}, new_args}
end
