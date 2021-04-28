defmodule Argx.Matcher do
  @moduledoc false

  import Argx.Error
  import Argx.Util

  alias Argx.{Converter, Const, Defaulter}
  alias Argx.Matcher.Helper

  @init_errors []
  @should_drop_flag Const.should_drop_flag()

  def match(from) do
    fn args, configs, curr_m ->
      with traverse <- traverse(from, args, configs),
           {root, path} <- {[], []} do
        traverse.(root, @init_errors, path, curr_m)
      end
    end
  end

  ###
  def traverse(_from, [] = _args, [] = _configs) do
    fn root, errors, _path, _curr_m ->
      {errors, Enum.reverse(root)}
    end
  end

  def traverse(from, [{arg_name, _arg_value} = arg | args_rest], [config | configs_rest]) do
    fn root, errors, path, curr_m ->
      with arg <- pre_args(arg, config, curr_m),
           errors <- collect_errors(arg, config, path, errors),
           drill_down <- drill_down(from, arg, config),
           {errors, root} <- drill_down.(root, errors, path ++ [arg_name], curr_m),
           traverse <- traverse(from, args_rest, configs_rest) do
        traverse.(root, errors, path, curr_m)
      end
    end
  end

  defp pre_args(arg, config, curr_m) do
    arg
    |> Defaulter.set_default(config, curr_m)
    |> Converter.convert(config)
  end

  defp collect_errors(arg, config, path, errors) do
    arg
    |> Helper.lacked(config, path, errors)
    |> Helper.error_type(path)
    |> Helper.out_of_range(path)
  end

  ###
  defp drill_down(
         _from,
         arg,
         {_arg_name2, %Argx.Config{type: :list, nested: nil}}
       ) do
    fn root, errors, _path, _curr_m ->
      {errors, [arg | root]}
    end
  end

  defp drill_down(
         from,
         {arg_name, arg_value},
         {_arg_name2, %Argx.Config{type: :list, nested: nested_configs}}
       )
       when is_list(arg_value) do
    fn root, errors, path, curr_m ->
      traverse_by_list(
        from,
        arg_value,
        nested_configs,
        root,
        errors,
        path,
        curr_m,
        arg_name
      )
    end
  end

  defp drill_down(
         from,
         {_arg_name, arg_value} = arg,
         _config
       ) do
    fn root, errors, _path, _curr_m ->
      if from == :argx and arg_value == @should_drop_flag do
        {errors, root}
      else
        {errors, [arg | root]}
      end
    end
  end

  ### Reenter Traverse Procedure
  def traverse_by_list(
        from,
        list,
        configs,
        root,
        errors,
        path,
        curr_m,
        parent
      ) do
    with line_num <- 1,
         result <-
           do_traverse_by_list(
             from,
             list,
             configs,
             [],
             errors,
             path,
             curr_m,
             parent,
             line_num
           ),
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
        new_list,
        errors,
        path,
        _curr_m,
        _parent,
        _line_num
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
        new_list,
        errors,
        _path,
        _curr_m,
        _parent,
        _line_num
      ) do
    {errors, new_list}
  end

  def do_traverse_by_list(
        from,
        [%{} = args | rest_args] = _list,
        configs,
        new_list,
        errors,
        path,
        curr_m,
        parent,
        line_num
      ) do
    with reenter <- reenter(from, args, configs),
         result <- reenter.(path, line_num, curr_m),
         continue <- continue(from, rest_args, configs) do
      continue.(new_list, errors, path, curr_m, parent, line_num, result)
    end
  end

  defp reenter(from, args, configs) do
    fn path, line_num, curr_m ->
      with {args, configs} <- Helper.pre_args_configs(args, configs),
           path <- Helper.append_path(path, line_num),
           traverse <- traverse(from, args, configs),
           list <- [] do
        traverse.(list, @init_errors, path, curr_m)
      end
    end
  end

  defp continue(from, [_ | _] = rest, configs) do
    fn list, errors, path, curr_m, parent, line_num, result ->
      with {new_errors, args} <- result,
           line_num <- line_num + 1,
           list <- [to_map(args) | list],
           errors <- merge_errors(errors, new_errors) do
        do_traverse_by_list(from, rest, configs, list, errors, path, curr_m, parent, line_num)
      end
    end
  end

  defp continue(_from, [] = _rest, _configs) do
    fn list, _errors, _path, _curr_m, _parent, _line_num, result ->
      with {new_errors, args} <- result,
           list <- [to_map(args) | list] do
        {new_errors, list}
      end
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
