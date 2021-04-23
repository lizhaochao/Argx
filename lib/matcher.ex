defmodule Argx.Matcher do
  @moduledoc false

  alias Argx.{Checker, Converter, Defaulter, Formatter, Parser, Util}

  @init_errors []

  def argx_match(args, config_names, current_m, general_m, get_configs) do
    Checker.check_args!(args)
    Checker.check_config_names!(config_names)

    configs = get_configs.(general_m, current_m, config_names) |> Enum.into([])
    origin_type = Util.get_type(args)

    current_m
    |> match(Enum.into(args, []), configs)
    |> Formatter.fmt_match_result(origin_type)
    |> Formatter.fmt_errors(current_m, general_m)
  end

  ###
  def match(current_m, args, configs, path \\ [])

  def match(current_m, [{_arg_name, _arg_value} | _] = args, [_ | _] = configs, path)
      when is_atom(current_m) do
    new_args =
      args
      |> Util.sort_by_keys(Keyword.keys(configs))
      |> Defaulter.set_default(configs, current_m)
      |> Converter.convert(configs)

    errors = traverse(@init_errors, new_args, configs, path)
    {errors, new_args}
  end

  def match(_, _, _, _), do: :match_error

  ###
  def traverse(errors, [], [], _path), do: errors

  def traverse(
        errors,
        [{arg_name, _arg_value} = arg | new_args_rest],
        [{_arg_name2, %Argx.Config{}} = config | configs_rest],
        path
      ) do
    new_errors =
      errors
      |> lacked(arg, config, path)
      |> error_type(path)
      |> out_of_range(path)
      |> drill_down(arg, config, path ++ [arg_name])

    traverse(new_errors, new_args_rest, configs_rest, path)
  end

  ###
  def lacked(
        errors,
        {arg_name, nil},
        {arg_name2, %Argx.Config{optional: false}},
        path
      )
      when arg_name == arg_name2 do
    reduce_errors(errors, arg_name, :lacked, path)
  end

  def lacked(
        errors,
        {arg_name, arg_value} = arg,
        {arg_name2, %Argx.Config{optional: false, type: type, empty: true}} = config,
        path
      )
      when arg_name == arg_name2 do
    if Checker.empty?(arg_value, type) do
      reduce_errors(errors, arg_name, :lacked, path)
    else
      {errors, arg, config}
    end
  end

  def lacked(
        errors,
        {arg_name, _} = arg,
        {arg_name2, _} = config,
        _path
      )
      when arg_name == arg_name2 do
    {errors, arg, config}
  end

  ###
  def error_type({errors, nil, nil}, _path), do: {errors, nil, nil}
  def error_type({errors, args, configs}, path), do: error_type(errors, args, configs, path)

  defp error_type(
         errors,
         {arg_name, nil},
         {arg_name2, %Argx.Config{optional: true}},
         _path
       )
       when arg_name == arg_name2 do
    {errors, nil, nil}
  end

  defp error_type(
         errors,
         {arg_name, arg_value} = arg,
         {arg_name2, %Argx.Config{type: type}} = config,
         path
       )
       when arg_name == arg_name2 do
    if Checker.some_type?(arg_value, type) do
      {errors, arg, config}
    else
      reduce_errors(errors, arg_name, :error_type, path)
    end
  end

  ###
  def out_of_range({errors, nil, nil}, _path), do: errors
  def out_of_range({errors, args, configs}, path), do: out_of_range(errors, args, configs, path)

  defp out_of_range(
         errors,
         {arg_name, nil},
         {arg_name2, %Argx.Config{optional: true}},
         _path
       )
       when arg_name == arg_name2 do
    errors
  end

  defp out_of_range(
         errors,
         {arg_name, _},
         {arg_name2, %Argx.Config{range: nil}},
         _path
       )
       when arg_name == arg_name2 do
    errors
  end

  defp out_of_range(
         errors,
         {arg_name, arg_value},
         {arg_name2, %Argx.Config{type: type, range: range}},
         path
       )
       when arg_name == arg_name2 do
    if Checker.in_range?(arg_value, Parser.parse_range(range), type) do
      errors
    else
      errors
      |> reduce_errors(arg_name, :out_of_range, path)
      |> out_of_range(path)
    end
  end

  ###
  defp drill_down(
         errors,
         {_arg_name, _arg_value},
         {_arg_name2, %Argx.Config{type: :list, nested: nil}},
         _path
       ) do
    errors
  end

  defp drill_down(
         errors,
         {_arg_name, [_ | _] = map_list},
         {_arg_name2, %Argx.Config{type: :list, nested: nested_configs}},
         path
       )
       when map_size(nested_configs) > 1 do
    {_num, merged_errors} =
      Enum.reduce(map_list, {1, errors}, fn map, {num, merged_errors} ->
        {new_errors, _new_args} =
          match(
            __MODULE__,
            Enum.into(map, []),
            Enum.into(nested_configs, []),
            path ++ ["#{num}"]
          )

        {num + 1, merge_errors(merged_errors, new_errors)}
      end)

    merged_errors
  end

  defp drill_down(
         errors,
         {_arg_name, _arg_value},
         {_arg_name2, %Argx.Config{}},
         _path
       ) do
    errors
  end

  ###
  defp reduce_errors(errors, field, check_type, path) do
    path = make_path(path, field)

    {nil, new_errors} =
      Keyword.get_and_update(errors, check_type, fn current ->
        new_value = (current && [path | current]) || [path]
        {nil, new_value}
      end)

    {new_errors, nil, nil}
  end

  defp merge_errors(a_err, b_err) when is_list(a_err) and is_list(b_err) do
    a_error_type = Keyword.get(a_err, :error_type, [])
    b_error_type = Keyword.get(b_err, :error_type, [])
    a_lacked = Keyword.get(a_err, :lacked, [])
    b_lacked = Keyword.get(b_err, :lacked, [])
    a_out_of_range = Keyword.get(a_err, :out_of_range, [])
    b_out_of_range = Keyword.get(b_err, :out_of_range, [])

    errors = []
    error_type = a_error_type ++ b_error_type
    lacked = a_lacked ++ b_lacked
    out_of_range = a_out_of_range ++ b_out_of_range
    errors = (error_type != [] && Keyword.put(errors, :error_type, error_type)) || errors
    errors = (lacked != [] && Keyword.put(errors, :lacked, lacked)) || errors
    (out_of_range != [] && Keyword.put(errors, :out_of_range, out_of_range)) || errors
  end

  defp merge_errors(_other_a_err, _other_b_err), do: []

  defp make_path([] = _path, field) when is_atom(field), do: field
  defp make_path([_ | _] = path, field), do: (path ++ [field]) |> Enum.join(":")
end
