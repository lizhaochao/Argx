defmodule Argx.Matcher do
  @moduledoc false

  import Argx.Error
  import Argx.Util

  alias Argx.{Converter, Const, Defaulter}
  alias Argx.Matcher.Helper

  @init_errors []
  @should_drop_flag Const.should_drop_flag()

  def from(from) do
    fn args, configs, curr_m ->
      match(from, args, configs, curr_m)
    end
  end

  ###
  def match(
        from,
        [{_arg_name, _arg_value} | _] = args,
        [{_arg_name2, %Argx.Config{}} | _] = configs,
        curr_m,
        root \\ [],
        path \\ []
      )
      when is_atom(curr_m) do
    traverse(root, path, from, args, configs, curr_m)
  end

  ###
  def traverse(root, path, from, args, configs, curr_m, errors \\ @init_errors)

  def traverse(root, _path, _from, [] = _args, [] = _configs, _curr_m, errors) do
    {errors, Enum.reverse(root)}
  end

  def traverse(
        root,
        path,
        from,
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
      |> drill_down(from, arg, config, root, path, curr_m)

    traverse(root, path, from, args_rest, configs_rest, curr_m, errors)
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
        from,
        {arg_name, _arg_value} = arg,
        config,
        root,
        path,
        curr_m
      ) do
    do_drill_down(errors, from, arg, config, root, path ++ [arg_name], curr_m)
  end

  defp do_drill_down(
         errors,
         _from,
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
         from,
         {arg_name, arg_value},
         {_arg_name2, %Argx.Config{type: :list, nested: nested_configs}},
         root,
         path,
         curr_m
       )
       when is_list(arg_value) do
    traverse_by_list(from, arg_value, nested_configs, arg_name, path, curr_m, root, errors)
  end

  defp do_drill_down(errors, from, {_arg_name, arg_value} = arg, _config, root, _path, _curr_m) do
    if from == :argx and arg_value == @should_drop_flag do
      {errors, root}
    else
      {errors, [arg | root]}
    end
  end

  ### Reenter Traverse Procedure
  def traverse_by_list(from, list, configs, parent, path, curr_m, root, errors) do
    with line_num <- 1,
         result <-
           do_traverse_by_list(from, list, configs, parent, path, curr_m, line_num, [], errors),
         {errors, list} <- result,
         list <- Enum.reverse(list),
         root <- Keyword.put(root, parent, list) do
      {errors, root}
    end
  end

  def do_traverse_by_list(
        _from,
        [] = _list,
        %{} = configs,
        _parent,
        path,
        _curr_m,
        _line_num,
        new_list,
        errors
      )
      when map_size(configs) > 0 do
    errors =
      configs
      |> Helper.get_required_key()
      |> Enum.reduce(errors, fn arg_name, errors ->
        {errors, _, _} = reduce_errors(errors, arg_name, path, &Helper.join_path/2, :lacked)
        errors
      end)

    {errors, new_list}
  end

  def do_traverse_by_list(
        _from,
        [] = _list,
        _configs,
        _parent,
        _path,
        _curr_m,
        _line_num,
        new_list,
        errors
      ) do
    {errors, new_list}
  end

  def do_traverse_by_list(
        from,
        [%{} = args | rest] = _list,
        configs,
        parent,
        path,
        curr_m,
        line_num,
        new_list,
        errors
      ) do
    from
    |> reenter(args, configs, path, line_num, curr_m)
    |> continue(errors, line_num, from, rest, configs, parent, path, curr_m, new_list)
  end

  defp reenter(from, args, configs, path, line_num, curr_m) do
    with {args, configs} <- Helper.pre_args_configs(args, configs),
         path <- Helper.append_path(path, line_num) do
      traverse([], path, from, args, configs, curr_m)
    end
  end

  defp continue(
         result,
         _errors,
         _line_num,
         _from,
         [] = _rest,
         _configs,
         _parent,
         _path,
         _curr_m,
         list
       ) do
    with {new_errors, args} <- result,
         list <- [to_map(args) | list] do
      {new_errors, list}
    end
  end

  defp continue(result, errors, line_num, from, rest, configs, parent, path, curr_m, list) do
    with {new_errors, args} <- result,
         line_num <- line_num + 1,
         list <- [to_map(args) | list],
         errors <- merge_errors(errors, new_errors) do
      do_traverse_by_list(from, rest, configs, parent, path, curr_m, line_num, list, errors)
    end
  end
end

defmodule Argx.Matcher.Helper do
  @moduledoc false

  import Argx.Error
  import Argx.Util

  alias Argx.{Checker, Const, Parser}

  @should_drop_flag Const.should_drop_flag()

  ###
  def lacked(
        {arg_name, arg_value},
        {arg_name2, %Argx.Config{optional: false}},
        path,
        errors
      )
      when arg_name == arg_name2 and (is_nil(arg_value) or arg_value == @should_drop_flag) do
    reduce_errors(errors, arg_name, path, &join_path/2, :lacked)
  end

  def lacked(
        {arg_name, arg_value} = arg,
        {arg_name2, %Argx.Config{optional: false, type: type, empty: true}} = config,
        path,
        errors
      )
      when arg_name == arg_name2 do
    if Checker.empty?(arg_value, type) do
      reduce_errors(errors, arg_name, path, &join_path/2, :lacked)
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
         {arg_name, arg_value},
         {arg_name2, %Argx.Config{optional: true}},
         _path
       )
       when arg_name == arg_name2 and (is_nil(arg_value) or arg_value == @should_drop_flag) do
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
      reduce_errors(errors, arg_name, path, &join_path/2, :error_type)
    end
  end

  ###
  def out_of_range({errors, nil, nil}, _path), do: errors
  def out_of_range({errors, args, configs}, path), do: out_of_range(errors, args, configs, path)

  defp out_of_range(
         errors,
         {arg_name, arg_value},
         {arg_name2, %Argx.Config{optional: true}},
         _path
       )
       when arg_name == arg_name2 and (is_nil(arg_value) or arg_value == @should_drop_flag) do
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
      |> reduce_errors(arg_name, path, &join_path/2, :out_of_range)
      |> out_of_range(path)
    end
  end

  ### Path
  def join_path(key, [] = _path) when is_atom(key), do: key

  def join_path(key, [_ | _] = path) do
    path
    |> Enum.reverse()
    |> hd()
    |> Kernel.==(key)
    |> if(
      do: path,
      else: path ++ [key]
    )
    |> Enum.join(":")
  end

  def append_path(path, num) when is_list(path) and is_integer(num), do: path ++ ["#{num}"]

  ### Preprocess
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
        Keyword.put(args, key, @should_drop_flag)
      end)
      |> Enum.reverse()

    arg_names = Keyword.keys(args)

    {args, arg_names}
  end

  defp get_lacked_keys(arg_names, config_names), do: config_names -- arg_names
  defp get_redundant_keys(arg_names, config_names), do: arg_names -- config_names

  def sort_by_keys(keyword, keys) when is_list(keyword) do
    keyword |> to_map() |> sort_by_keys(keys)
  end

  def sort_by_keys(%{} = map, keys) do
    keys
    |> Enum.reduce([], fn key, keyword ->
      value = Map.get(map, key, @should_drop_flag)
      (value && [{key, value} | keyword]) || keyword
    end)
    |> Enum.reverse()
  end

  def get_required_key(configs) do
    configs
    |> Enum.into([])
    |> Enum.filter(fn {_field, config} ->
      config.optional == false
    end)
    |> Keyword.keys()
  end
end
