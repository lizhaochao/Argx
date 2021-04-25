defmodule Argx.Matcher do
  @moduledoc false

  alias Argx.{Checker, Converter, Defaulter, Parser, Util}
  alias Argx.Matcher.Helper

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
    arg = pre_process_args(arg, config, curr_m)

    {errors, ok_args} =
      arg
      |> collect_errors(config, path, errors)
      |> drill_down(arg, config, ok_args, path, curr_m)

    traverse(ok_args, path, args_rest, configs_rest, curr_m, errors)
  end

  def pre_process_args(arg, config, curr_m) do
    [arg] =
      [arg]
      |> Defaulter.set_default([config], curr_m)
      |> Converter.convert([config])

    arg
  end

  def collect_errors(arg, config, path, errors) do
    arg
    |> lacked(config, path, errors)
    |> error_type(path)
    |> out_of_range(path)
  end

  ###
  def lacked(
        {arg_name, nil},
        {arg_name2, %Argx.Config{optional: false}},
        path,
        errors
      )
      when arg_name == arg_name2 do
    Helper.reduce_errors(errors, arg_name, path, :lacked)
  end

  def lacked(
        {arg_name, arg_value} = arg,
        {arg_name2, %Argx.Config{optional: false, type: type, empty: true}} = config,
        path,
        errors
      )
      when arg_name == arg_name2 do
    if Checker.empty?(arg_value, type) do
      Helper.reduce_errors(errors, arg_name, path, :lacked)
    else
      {errors, arg, config}
    end
  end

  def lacked(
        {arg_name, _} = arg,
        {arg_name2, _} = config,
        _path,
        errors
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
      Helper.reduce_errors(errors, arg_name, path, :error_type)
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
      |> Helper.reduce_errors(arg_name, path, :out_of_range)
      |> out_of_range(path)
    end
  end

  ###
  def drill_down(
        errors,
        {arg_name, _arg_value} = arg,
        config,
        ok_args,
        path,
        curr_m
      ) do
    do_drill_down(errors, arg, config, ok_args, path ++ [arg_name], curr_m)
  end

  defp do_drill_down(
         errors,
         {arg_name, arg_value},
         {_arg_name2, %Argx.Config{type: :list, nested: nil}},
         ok_args,
         _path,
         _curr_m
       ) do
    ok_args = [{arg_name, arg_value} | ok_args]
    {errors, ok_args}
  end

  defp do_drill_down(
         errors,
         {arg_name, [_ | _] = arg_value},
         {_arg_name2, %Argx.Config{type: :list, nested: nested_configs}},
         ok_args,
         path,
         curr_m
       )
       when map_size(nested_configs) > 1 do
    traverse_by_list(arg_value, nested_configs, ok_args, arg_name, path, curr_m, errors)
  end

  defp do_drill_down(
         errors,
         {_arg_name, _arg_value} = arg,
         {_arg_name2, %Argx.Config{}},
         ok_args,
         _path,
         _curr_m
       ) do
    {errors, [arg | ok_args]}
  end

  def traverse_by_list(list, configs, ok_args, parent_arg_name, path, curr_m, errors) do
    {errors, new_list} =
      do_traverse_by_list(
        list,
        configs,
        parent_arg_name,
        path,
        curr_m,
        {1, errors, []}
      )

    ok_args = Util.append(Enum.into(new_list, %{}), ok_args, parent_arg_name)
    {errors, ok_args}
  end

  def do_traverse_by_list(
        [] = _list,
        _configs,
        _parent_arg_name,
        _path,
        _curr_m,
        {_num, errors, ok_args}
      ) do
    {errors, ok_args}
  end

  def do_traverse_by_list(
        [args | list_rest],
        configs,
        parent_arg_name,
        path,
        curr_m,
        {num, merged_errors, new_map}
      ) do
    configs = Util.to_keyword(configs)
    new_args = Util.sort_by_keys(args, Keyword.keys(configs))
    num_path = path ++ ["#{num}"]
    {errors, item} = traverse(new_map, num_path, new_args, configs, curr_m)
    new_map = Keyword.merge(new_map, item)

    acc = {
      num + 1,
      Helper.merge_errors(merged_errors, errors),
      new_map
    }

    do_traverse_by_list(list_rest, configs, parent_arg_name, path, curr_m, acc)
  end
end

defmodule Argx.Matcher.Helper do
  @moduledoc false

  alias Argx.Util

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
