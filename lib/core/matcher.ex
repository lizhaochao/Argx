defmodule Argx.Matcher do
  @moduledoc false

  import Argx.Error

  alias Argx.Const
  alias Argx.Matcher.Helper

  @init_errors []
  @should_drop_flag Const.should_drop_flag()
  @check_types Const.check_types()
  @value_key Const.value_key()

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
      with arg <- Helper.pre_process_args(arg, config, curr_m),
           errors <- Helper.collect_errors(arg, config, path, errors),
           drill_down <- drill_down(from, arg, config),
           new_path <- Helper.append_path(path, arg_name),
           {errors, root} <- drill_down.(root, errors, @should_drop_flag, new_path, curr_m),
           traverse <- traverse(from, args_rest, configs_rest) do
        traverse.(root, errors, path, curr_m)
      end
    end
  end

  ###
  defp drill_down(
         _from,
         arg,
         {_arg_name2, %Argx.Config{type: type, nested: nil}}
       )
       when type in [:list, :map] do
    fn root, errors, _should_drop_flag, _path, _curr_m ->
      {errors, [arg | root]}
    end
  end

  defp drill_down(
         from,
         {arg_name, arg_value},
         {_arg_name2, %Argx.Config{type: :list, nested: nested_configs}}
       )
       when is_list(arg_value) do
    fn root, errors, _should_drop_flag, path, curr_m ->
      with value_type <- Helper.get_value_type_by_configs(nested_configs, @value_key),
           worker <- traverse_by_list(from, arg_value, nested_configs) do
        worker.(root, errors, path, curr_m, arg_name, value_type)
      end
    end
  end

  defp drill_down(
         from,
         {arg_name, arg_value},
         {_arg_name2, %Argx.Config{type: :map, nested: nested_configs}}
       )
       when is_map(arg_value) do
    fn root, errors, _should_drop_flag, path, curr_m ->
      with worker <- traverse_by_map(from, arg_value, nested_configs) do
        worker.(root, errors, path, curr_m, arg_name, :map)
      end
    end
  end

  defp drill_down(from, {_arg_name, arg_value} = arg, _config) do
    fn root, errors, should_drop_flag, _path, _curr_m ->
      with :argx <- from,
           true <- should_drop_flag == arg_value do
        {errors, root}
      else
        _ -> {errors, [arg | root]}
      end
    end
  end

  ### Reenter Traverse Procedure
  defp traverse_by_map(from, list, configs) do
    fn root, errors, path, curr_m, parent, value_type ->
      with worker <- reenter(from, list, configs),
           {new_errors, map} <- worker.(path, curr_m, nil),
           errors <- merge_errors(errors, new_errors, @check_types),
           map <- Helper.return_child(map, value_type),
           root <- Keyword.put(root, parent, map) do
        {errors, root}
      end
    end
  end

  defp traverse_by_list(from, list, configs) do
    fn root, errors, path, curr_m, parent, value_type ->
      with list <- Helper.build_list(list, value_type, @value_key),
           new_list <- [],
           line_num <- 1,
           worker <- do_traverse_by_list(from, list, configs),
           {errors, list} <-
             worker.(new_list, errors, path, curr_m, parent, line_num),
           list <- Helper.return_child(list, value_type),
           root <- Keyword.put(root, parent, list) do
        {errors, root}
      end
    end
  end

  defp do_traverse_by_list(_from, [] = _list, %{} = configs) when map_size(configs) > 0 do
    fn new_list, errors, path, _curr_m, _parent, _line_num ->
      with lacked_keys <- Helper.get_required_key(configs, @value_key),
           new_errors <- reduce_errors(errors, lacked_keys, path, &Helper.join_path/2, :lacked) do
        {new_errors, new_list}
      end
    end
  end

  defp do_traverse_by_list(_from, [] = _list, _configs) do
    fn new_list, errors, _path, _curr_m, _parent, _line_num ->
      {errors, new_list}
    end
  end

  defp do_traverse_by_list(from, [args | rest_args] = _list, configs) do
    fn new_list, errors, path, curr_m, parent, line_num ->
      with %{} <- args,
           reenter <- reenter(from, args, configs),
           result <- reenter.(path, curr_m, line_num),
           continue <- continue(from, rest_args, configs) do
        continue.(new_list, errors, path, curr_m, parent, line_num, result)
      else
        _ ->
          {errors, _, _} = reduce_errors(errors, nil, path, &Helper.join_path/2, :error_type)
          {errors, new_list}
      end
    end
  end

  ###
  defp reenter(from, args, configs) do
    fn path, curr_m, line_num ->
      with {args, configs} <- Helper.pre_args_configs(args, configs),
           path <- Helper.append_path(path, line_num),
           traverse <- traverse(from, args, configs),
           new_list <- [] do
        traverse.(new_list, @init_errors, path, curr_m)
      end
    end
  end

  defp continue(from, [_ | _] = rest, configs) do
    fn new_list, errors, path, curr_m, parent, line_num, result ->
      with {new_errors, args} <- result,
           line_num <- line_num + 1,
           errors <- merge_errors(errors, new_errors, @check_types),
           list <- Helper.reduce_list(args, new_list),
           worker <- do_traverse_by_list(from, rest, configs) do
        worker.(list, errors, path, curr_m, parent, line_num)
      end
    end
  end

  defp continue(_from, [] = _rest, _configs) do
    fn new_list, errors, _path, _curr_m, _parent, _line_num, result ->
      with {new_errors, args} <- result,
           errors <- merge_errors(errors, new_errors, @check_types),
           list <- Helper.reduce_list(args, new_list) do
        {errors, list}
      end
    end
  end
end

defmodule Argx.Matcher.Helper do
  @moduledoc false

  alias Argx.{Checker, Converter, Const, Defaulter, Util}

  @should_drop_flag Const.should_drop_flag()
  @value_key Const.value_key()
  @path_sep ":"

  def pre_process_args(arg, config, curr_m) do
    arg
    |> Defaulter.set_default(config, curr_m)
    |> Converter.convert(config)
  end

  def collect_errors(arg, config, path, errors) do
    arg
    |> Checker.lacked(config, path, errors, &join_path/2)
    |> Checker.error_type(path, &join_path/2)
    |> Checker.out_of_range(path, &join_path/2)
  end

  def get_required_key(configs, value_key) do
    configs
    |> to_keyword()
    |> Enum.filter(fn {field, config} ->
      config.optional == false and field != value_key
    end)
    |> Keyword.keys()
  end

  def get_value_type_by_configs(configs, value_key) do
    with [key | []] <- Map.keys(configs),
         true <- key == value_key do
      :value
    else
      _ -> :list
    end
  end

  def build_list(list, :value, value_key) when is_list(list) do
    Enum.map(list, fn term ->
      %{value_key => term}
    end)
  end

  def build_list(list, :list, _value_key), do: list
  def build_list(other, _value_type, _value_key), do: other

  def return_child([_ | _] = list, :value) do
    list
    |> Enum.map(fn term ->
      %{_: value} = term
      value
    end)
    |> Enum.reverse()
  end

  def return_child([_ | _] = list, :list), do: Enum.reverse(list)
  def return_child([_ | _] = map, :map), do: to_map(map)
  def return_child(other_list, _value_type), do: other_list

  def reduce_list(args, new_list) when is_list(args) and is_list(new_list) do
    [to_map(args) | new_list]
  end

  def reduce_list(_other_args, new_list) when is_list(new_list), do: new_list

  ### Path
  def join_path(key, path, sep \\ @path_sep, value_key \\ @value_key)
  def join_path(key, [] = _path, _sep, _value_key) when is_atom(key), do: key
  def join_path(nil = _key, [path | []], _sep, _value_key), do: path
  def join_path(nil = _key, [_ | _] = path, sep, _value_key), do: path |> Enum.join(sep)

  def join_path(key, [_ | _] = path, sep, _value_key) do
    path |> append_path(key) |> Enum.join(sep)
  end

  def append_path(path, term, value_key \\ @value_key)
  def append_path(path, nil = _term, _value_key) when is_list(path), do: path
  def append_path(path, term, value_key) when is_list(path) and term == value_key, do: path
  def append_path(path, term, _value_key) when is_list(path) and is_atom(term), do: path ++ [term]

  def append_path(path, num, _value_key) when is_list(path) and is_integer(num) do
    path ++ ["#{num}"]
  end

  ### Preprocess
  def pre_args_configs(args, configs) when is_map(args) or is_map(configs) do
    args
    |> Util.to_atom_key()
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
         configs <- sort_by_keys(configs, arg_names, @should_drop_flag) do
      {args, configs}
    end
  end

  defp sort_by_lacked_key([_ | _] = lacked_keys, args, configs) do
    with {args, arg_names} <- fill_by_lacked_keys(args, lacked_keys, @should_drop_flag),
         configs <- sort_by_keys(configs, arg_names, @should_drop_flag) do
      {args, configs}
    end
  end

  defp drop_by_redundant_keys(args, redundant_keys) do
    with args <- Keyword.drop(args, redundant_keys),
         arg_names <- Keyword.keys(args) do
      {args, arg_names}
    end
  end

  defp fill_by_lacked_keys(args, lacked_keys, should_drop_flag) do
    args =
      lacked_keys
      |> Enum.reduce(Enum.reverse(args), fn key, args ->
        Keyword.put(args, key, should_drop_flag)
      end)
      |> Enum.reverse()

    arg_names = Keyword.keys(args)

    {args, arg_names}
  end

  defp get_lacked_keys(arg_names, config_names), do: config_names -- arg_names
  defp get_redundant_keys(arg_names, config_names), do: arg_names -- config_names

  def sort_by_keys(keyword, keys, should_drop_flag) when is_list(keyword) do
    keyword |> to_map() |> sort_by_keys(keys, should_drop_flag)
  end

  def sort_by_keys(%{} = map, keys, should_drop_flag) do
    keys
    |> Enum.reduce([], fn key, keyword ->
      value = Map.get(map, key, should_drop_flag)
      (value && [{key, value} | keyword]) || keyword
    end)
    |> Enum.reverse()
  end

  def to_map(%{} = term), do: term
  def to_map(term) when is_list(term), do: Map.new(term)
  def to_map(other), do: other
  def to_keyword(%{} = term), do: Keyword.new(term)
  def to_keyword(term) when is_list(term), do: term
  def to_keyword(other), do: other

  ###
  def get_type(%{} = _term), do: :map
  def get_type(term) when is_bitstring(term), do: :string
  def get_type(term) when is_integer(term), do: :integer
  def get_type(term) when is_float(term), do: :float

  def get_type(term) when is_list(term) do
    term
    |> Keyword.keyword?()
    |> if(
      do: :keyword,
      else: :list
    )
  end

  def get_type(_other), do: :unknown

  ### Proxy
  def prune_names(term), do: Util.prune_names(term)
end
