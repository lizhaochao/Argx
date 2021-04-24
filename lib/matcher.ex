defmodule Argx.Matcher do
  @moduledoc false

  alias Argx.{Checker, Converter, Defaulter, Parser, Util}
  alias Argx.Matcher.Helper, as: H

  @init_errors []

  ###
  def match(
        [{_arg_name, _arg_value} | _] = args,
        [{_arg_name2, %Argx.Config{}} | _] = configs,
        curr_m,
        ok_args \\ [],
        path \\ []
      )
      when is_atom(curr_m) do
    traverse(ok_args, path, args, configs, curr_m)
  end

  ###
  def traverse(ok_args, path, args, configs, curr_m, errors \\ @init_errors)

  def traverse(ok_args, _path, [] = _args, [] = _configs, _curr_m, errors) do
    {errors, Enum.reverse(ok_args)}
  end

  def traverse(
        ok_args,
        path,
        [arg | args_rest],
        [config | configs_rest],
        curr_m,
        errors
      )
      when is_list(ok_args) and is_list(path) and is_list(errors) do
    [{arg_name, _arg_value} = arg] =
      [arg]
      |> Defaulter.set_default([config], curr_m)
      |> Converter.convert([config])

    {errors, ok_args} =
      errors
      |> lacked(arg, config, path)
      |> error_type(path)
      |> out_of_range(path)
      |> drill_down(arg, config, curr_m, ok_args, path ++ [arg_name])

    traverse(ok_args, path, args_rest, configs_rest, curr_m, errors)
  end

  ###
  def lacked(
        errors,
        {arg_name, nil},
        {arg_name2, %Argx.Config{optional: false}},
        path
      )
      when arg_name == arg_name2 do
    H.reduce_errors(errors, arg_name, path, :lacked)
  end

  def lacked(
        errors,
        {arg_name, arg_value} = arg,
        {arg_name2, %Argx.Config{optional: false, type: type, empty: true}} = config,
        path
      )
      when arg_name == arg_name2 do
    if Checker.empty?(arg_value, type) do
      H.reduce_errors(errors, arg_name, path, :lacked)
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
      H.reduce_errors(errors, arg_name, path, :error_type)
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
      |> H.reduce_errors(arg_name, path, :out_of_range)
      |> out_of_range(path)
    end
  end

  ###
  defp drill_down(
         errors,
         {arg_name, arg_value},
         {_arg_name2, %Argx.Config{type: :list, nested: nil}},
         _curr_m,
         ok_args,
         _path
       ) do
    ok_args = [{arg_name, arg_value} | ok_args]
    {errors, ok_args}
  end

  defp drill_down(
         errors,
         {arg_name, [_ | _] = arg_value},
         {_arg_name2, %Argx.Config{type: :list, nested: nested_configs}},
         curr_m,
         ok_args,
         path
       )
       when map_size(nested_configs) > 1 do
    {_num, new_errors, ok_args} =
      Enum.reduce(arg_value, {1, errors, ok_args}, fn args, {num, acc_errors, ok_args} ->
        processed_args = prepare_args(args, nested_configs, curr_m)

        {new_errors, ok_args} =
          traverse(
            ok_args,
            path ++ ["#{num}"],
            processed_args,
            Enum.into(nested_configs, []),
            curr_m
          )

        ok_args =
          args
          |> Util.get_type()
          |> Util.restore(processed_args)
          |> Util.append(ok_args, arg_name)

        merged_errors = H.merge_errors(acc_errors, new_errors)
        {num + 1, merged_errors, ok_args}
      end)

    {new_errors, ok_args}
  end

  defp drill_down(
         errors,
         {arg_name, arg_value},
         {_arg_name2, %Argx.Config{}},
         _curr_m,
         ok_args,
         path
       ) do
    ok_args =
      path
      |> H.is_nested?()
      |> if(
        do: ok_args,
        else: [{arg_name, arg_value} | ok_args]
      )

    {errors, ok_args}
  end

  ###
  defp prepare_args(args, configs, curr_m) when is_atom(curr_m) do
    configs = Util.to_keyword(configs)

    args
    |> Util.sort_by_keys(Keyword.keys(configs))
    |> Defaulter.set_default(configs, curr_m)
    |> Converter.convert(configs)
  end
end

defmodule Argx.Matcher.Helper do
  @moduledoc false

  alias Argx.Util

  ###
  def is_nested?([_ | _] = path), do: do_is_nested?(path, false)
  def is_nested?([] = _path), do: false
  def is_nested?(_other_path), do: false

  def do_is_nested?([], result?), do: result?

  def do_is_nested?([term | rest_path], _result?) do
    term
    |> to_string()
    |> Integer.parse()
    |> case do
      {_integer, ""} -> do_is_nested?([], true)
      _ -> do_is_nested?(rest_path, false)
    end
  end

  ###
  def reduce_errors(errors, key, path, check_type) do
    new_errors = key |> make_path(path) |> Util.append(errors, check_type)
    {new_errors, nil, nil}
  end

  def merge_errors(a_err, b_err) when is_list(a_err) and is_list(b_err) do
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

  def merge_errors(_other_a_err, _other_b_err), do: []

  def make_path(key, [] = _path) when is_atom(key), do: key
  def make_path(key, [_ | _] = path), do: (path ++ [key]) |> Enum.join(":")
end
