defmodule Argx.Matcher do
  @moduledoc false

  import Argx.Util

  alias Argx.{Converter, Defaulter}
  alias Argx.Matcher.Helper

  @init_errors []

  ###
  def match(
        [{_arg_name, _arg_value} | _] = args,
        [{_arg_name2, %Argx.Config{}} | _] = configs,
        curr_m,
        root \\ [],
        path \\ []
      )
      when is_atom(curr_m) do
    traverse(root, path, args, configs, curr_m)
  end

  ###
  def traverse(root, path, args, configs, curr_m, errors \\ @init_errors)

  def traverse(root, _path, [] = _args, [] = _configs, _curr_m, errors) do
    {errors, Enum.reverse(root)}
  end

  def traverse(
        root,
        path,
        [arg | args_rest],
        [config | configs_rest],
        curr_m,
        errors
      )
      when is_list(root) and is_list(path) and is_list(errors) do
    arg = pre_args(arg, config, curr_m)

    {errors, root} =
      arg
      |> collect_errors(config, path, errors)
      |> drill_down(arg, config, root, path, curr_m)

    traverse(root, path, args_rest, configs_rest, curr_m, errors)
  end

  def pre_args(arg, config, curr_m) do
    arg
    |> Defaulter.set_default(config, curr_m)
    |> Converter.convert(config)
  end

  def collect_errors(arg, config, path, errors) do
    arg
    |> Helper.lacked(config, path, errors)
    |> Helper.error_type(path)
    |> Helper.out_of_range(path)
  end

  ###
  def drill_down(
        errors,
        {arg_name, _arg_value} = arg,
        config,
        root,
        path,
        curr_m
      ) do
    do_drill_down(errors, arg, config, root, path ++ [arg_name], curr_m)
  end

  defp do_drill_down(
         errors,
         arg,
         {_arg_name2, %Argx.Config{type: :list, nested: nil}},
         root,
         _path,
         _curr_m
       ) do
    {errors, [arg | root]}
  end

  defp do_drill_down(
         errors,
         {arg_name, [_ | _] = arg_value},
         {_arg_name2, %Argx.Config{type: :list, nested: nested_configs}},
         root,
         path,
         curr_m
       )
       when map_size(nested_configs) > 1 do
    traverse_by_list(arg_value, nested_configs, arg_name, path, curr_m, root, errors)
  end

  defp do_drill_down(
         errors,
         {_arg_name, _arg_value} = arg,
         {_arg_name2, %Argx.Config{}},
         root,
         _path,
         _curr_m
       ) do
    {errors, [arg | root]}
  end

  ### Reenter Traverse Procedure
  def traverse_by_list(list, configs, parent, path, curr_m, root, errors) do
    result = do_traverse_by_list(list, configs, parent, path, curr_m, 1, [], errors)
    {errors, list} = result

    root = Keyword.put(root, parent, Enum.reverse(list))
    {errors, root}
  end

  def do_traverse_by_list([] = _list, _configs, _parent, _path, _curr_m, _num, new_list, errors) do
    {errors, new_list}
  end

  def do_traverse_by_list(
        [%{} = args | rest] = _list,
        configs,
        parent,
        path,
        curr_m,
        num,
        new_list,
        errors
      ) do
    args
    |> reenter(configs, path, num, curr_m)
    |> continue(errors, num, rest, configs, parent, path, curr_m, new_list)
  end

  defp reenter(args, configs, path, num, curr_m) do
    {args, configs} = Helper.pre_args_configs(args, configs)
    path = Helper.append_path(path, num)
    traverse([], path, args, configs, curr_m)
  end

  defp continue({new_error, args}, errors, num, rest, configs, parent, path, curr_m, list) do
    num = num + 1
    list = [to_map(args) | list]
    errors = Helper.merge_errors(errors, new_error)
    do_traverse_by_list(rest, configs, parent, path, curr_m, num, list, errors)
  end
end

defmodule Argx.Matcher.Helper do
  @moduledoc false

  import Argx.Util

  alias Argx.{Checker, Const, Parser}

  ###
  def lacked(
        {arg_name, nil},
        {arg_name2, %Argx.Config{optional: false}},
        path,
        errors
      )
      when arg_name == arg_name2 do
    reduce_errors(errors, arg_name, path, :lacked)
  end

  def lacked(
        {arg_name, arg_value} = arg,
        {arg_name2, %Argx.Config{optional: false, type: type, empty: true}} = config,
        path,
        errors
      )
      when arg_name == arg_name2 do
    if Checker.empty?(arg_value, type) do
      reduce_errors(errors, arg_name, path, :lacked)
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
      reduce_errors(errors, arg_name, path, :error_type)
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
      |> reduce_errors(arg_name, path, :out_of_range)
      |> out_of_range(path)
    end
  end

  ### Process Errors
  def reduce_errors(errors, key, path, check_type) do
    new_errors = key |> join_path(path) |> append(errors, check_type)
    {new_errors, nil, nil}
  end

  def merge_errors(left, right) when is_list(left) and is_list(right) do
    do_merger_errors(
      [],
      left |> pre_errors() |> Enum.sort(),
      right |> pre_errors() |> Enum.sort()
    )
  end

  defp pre_errors(errors) when is_list(errors) do
    Enum.reduce(Const.check_types(), errors, fn type, err ->
      {_, new} =
        Keyword.get_and_update(err, type, fn current ->
          {nil, current || []}
        end)

      new
    end)
  end

  defp do_merger_errors(new_errors, [] = _left, [] = _right), do: Enum.reverse(new_errors)

  defp do_merger_errors(
         new_errors,
         [{l_type, l_value} | l_rest],
         [{r_type, r_value} | r_rest]
       )
       when l_type == r_type do
    value =
      case {l_value, r_value} do
        {[], []} -> nil
        {[], [_ | _]} -> r_value
        {[_ | _], []} -> l_value
        {[_ | _], [_ | _]} -> l_value ++ r_value
      end

    value
    |> Kernel.&&([{l_type, Enum.sort(value)} | new_errors])
    |> Kernel.||(new_errors)
    |> do_merger_errors(l_rest, r_rest)
  end

  ### Path
  def join_path(key, [] = _path) when is_atom(key), do: key
  def join_path(key, [_ | _] = path), do: (path ++ [key]) |> Enum.join(":")

  def append_path(path, num) when is_list(path) and is_integer(num), do: path ++ ["#{num}"]

  ###
  def pre_args_configs(args, configs) when is_map(args) or is_map(configs) do
    args
    |> to_keyword()
    |> pre_args_configs(to_keyword(configs))
  end

  def pre_args_configs(args, configs) when is_list(args) and is_list(configs) do
    with {arg_names, config_names} <- {Keyword.keys(args), Keyword.keys(configs)},
         redundant_keys <- get_redundant_keys(arg_names, config_names),
         {args, arg_names} <- drop_by_redundant_keys(args, redundant_keys),
         lacked_keys <- get_lacked_keys(arg_names, config_names) do
      sort_by_lacked_key(lacked_keys, args, configs)
    end
  end

  defp sort_by_lacked_key([] = _lacked_keys, args, configs) do
    with arg_names <- Keyword.keys(args),
         configs <- sort_by_keys(configs, arg_names) do
      {args, configs}
    end
  end

  defp sort_by_lacked_key([_ | _] = lacked_keys, args, configs) do
    with {args, arg_names} <- fill_by_lacked_keys(args, lacked_keys),
         configs <- sort_by_keys(configs, arg_names) do
      {args, configs}
    end
  end

  defp drop_by_redundant_keys(args, redundant_keys) do
    with args <- Keyword.drop(args, redundant_keys),
         arg_names <- Keyword.keys(args) do
      {args, arg_names}
    end
  end

  defp fill_by_lacked_keys(args, lacked_keys) do
    args =
      lacked_keys
      |> Enum.reduce(Enum.reverse(args), fn key, args ->
        Keyword.put(args, key, nil)
      end)
      |> Enum.reverse()

    arg_names = Keyword.keys(args)

    {args, arg_names}
  end

  defp get_lacked_keys(arg_names, config_names), do: config_names -- arg_names
  defp get_redundant_keys(arg_names, config_names), do: arg_names -- config_names
end
