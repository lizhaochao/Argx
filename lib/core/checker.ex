defmodule Argx.Checker do
  @moduledoc false

  import Argx.Error

  alias Argx.{Const, Parser}

  @allowed_fun_types Const.allowed_fun_types()
  @configs_keyword Const.configs_keyword()
  @should_drop_flag Const.should_drop_flag()

  ###
  def lacked(
        {arg_name, arg_value},
        {arg_name2, %Argx.Config{optional: false}},
        path,
        errors,
        path_handler
      )
      when arg_name == arg_name2 and (is_nil(arg_value) or arg_value == @should_drop_flag) do
    reduce_errors(errors, arg_name, path, path_handler, :lacked)
  end

  def lacked(
        {arg_name, arg_value} = arg,
        {arg_name2, %Argx.Config{optional: false, type: type, empty: true}} = config,
        path,
        errors,
        path_handler
      )
      when arg_name == arg_name2 do
    if empty?(arg_value, type) do
      reduce_errors(errors, arg_name, path, path_handler, :lacked)
    else
      {errors, arg, config}
    end
  end

  def lacked(
        {arg_name, _} = arg,
        {arg_name2, _} = config,
        _path,
        errors,
        _path_handler
      )
      when arg_name == arg_name2 do
    {errors, arg, config}
  end

  ###
  def error_type({errors, nil, nil}, _path, _path_handler) do
    {errors, nil, nil}
  end

  def error_type({errors, args, configs}, path, path_handler) do
    error_type(errors, args, configs, path, path_handler)
  end

  defp error_type(
         errors,
         {arg_name, arg_value},
         {arg_name2, %Argx.Config{optional: true}},
         _path,
         _path_handler
       )
       when arg_name == arg_name2 and (is_nil(arg_value) or arg_value == @should_drop_flag) do
    {errors, nil, nil}
  end

  defp error_type(
         errors,
         {arg_name, arg_value} = arg,
         {arg_name2, %Argx.Config{type: type}} = config,
         path,
         path_handler
       )
       when arg_name == arg_name2 do
    if some_type?(arg_value, type) do
      {errors, arg, config}
    else
      reduce_errors(errors, arg_name, path, path_handler, :error_type)
    end
  end

  ###
  def out_of_range({errors, nil, nil}, _path, _path_handler) do
    errors
  end

  def out_of_range({errors, args, configs}, path, path_handler) do
    out_of_range(errors, args, configs, path, path_handler)
  end

  defp out_of_range(
         errors,
         {arg_name, arg_value},
         {arg_name2, %Argx.Config{optional: true}},
         _path,
         _path_handler
       )
       when arg_name == arg_name2 and (is_nil(arg_value) or arg_value == @should_drop_flag) do
    errors
  end

  defp out_of_range(
         errors,
         {arg_name, _},
         {arg_name2, %Argx.Config{range: nil}},
         _path,
         _path_handler
       )
       when arg_name == arg_name2 do
    errors
  end

  defp out_of_range(
         errors,
         {arg_name, arg_value},
         {arg_name2, %Argx.Config{type: type, range: range}},
         path,
         path_handler
       )
       when arg_name == arg_name2 do
    if in_range?(arg_value, Parser.parse_range(range), type) do
      errors
    else
      errors
      |> reduce_errors(arg_name, path, path_handler, :out_of_range)
      |> out_of_range(path, path_handler)
    end
  end

  ### Argx
  def check_args!(%{} = _args), do: :ignore

  def check_args!(args) when is_list(args) do
    args
    |> Keyword.keyword?()
    |> if(
      do: :ignore,
      else: raise(Argx.Error, "args must be map or keyword")
    )
  end

  def check_args!(_other_args), do: raise(Argx.Error, "args must be map or keyword")

  def check_config_names!(config_names) do
    case config_names do
      [_ | _] -> :ignore
      _ -> raise Argx.Error, "config names must be list & not empty"
    end
  end

  ### with check macro
  def check!(configs, block) do
    with :ok <- check_configs(configs),
         :ok = ok <- check_block(block) do
      ok
    else
      :configs_error -> raise Argx.Error, "not found #{@configs_keyword} keyword"
      :block_error -> raise Argx.Error, "unknown function type"
      :block_empty_error -> raise Argx.Error, "required one function at least"
      _ -> :ok
    end
  end

  defp check_configs({configs_keyword, _, _}) when configs_keyword == @configs_keyword, do: :ok
  defp check_configs(_), do: :configs_error

  defp check_block({:__block__, _, [expr | _]}), do: check_block(expr)
  defp check_block({fun_type, _, _}) when fun_type in @allowed_fun_types, do: :ok
  defp check_block({:__block__, [], []}), do: :block_empty_error
  defp check_block(_), do: :block_error

  ### defconfig macro
  def check_defconfig!(_name, [_ | _] = configs), do: check_defconfig!(configs)
  def check_defconfig!(_name, {_, _, _} = config), do: check_defconfig!([config])
  def check_defconfig!(_name, []), do: raise(Argx.Error, "configs is empty")

  def check_defconfig!([{:||, _, [{_, _, _} = config, _]} | _]), do: check_defconfig!(config)
  def check_defconfig!([{_, _, _} = config | _]), do: check_defconfig!(config)
  def check_defconfig!({_, _, [_ | _]}), do: :ok
  def check_defconfig!({_, _, []}), do: raise(Argx.Error, "at least config type")

  ###
  def some_type?(term, :integer), do: is_integer(term)
  def some_type?(term, :float), do: is_float(term)
  def some_type?(term, :string), do: is_bitstring(term)
  def some_type?(term, :list), do: is_list(term)
  def some_type?(term, :map), do: is_map(term)
  def some_type?(term, :boolean), do: is_boolean(term)
  def some_type?(_other_term, _other_type), do: false

  def in_range?(term, [l, r], :integer) when is_integer(term) do
    (term >= l and term <= r) or (term == l and term == r)
  end

  def in_range?(term, [l, r], :float) when is_float(term) do
    (term >= l and term <= r) or (term == l and term == r)
  end

  def in_range?(term, [l, r], :string) when is_bitstring(term) do
    len = String.length(term)
    (len >= l and len <= r) or (len == l and len == r)
  end

  def in_range?(term, [l, r], :list) when is_list(term) do
    len = length(term)
    (len >= l and len <= r) or (len == l and len == r)
  end

  def in_range?(term, [l, r], :map) when is_map(term) do
    len = map_size(term)
    (len >= l and len <= r) or (len == l and len == r)
  end

  def in_range?(term, [_l, _r], :boolean) when is_boolean(term) do
    true
  end

  def in_range?(_other_term, _range, _other_type), do: false

  def empty?(0, :integer), do: true
  def empty?(0.0, :float), do: true
  def empty?("", :string), do: true
  def empty?([], :list), do: true
  def empty?(%{} = term, :map), do: Enum.empty?(term)
  def empty?(_other_term, _other_type), do: false

  def are_keys_equal!(
        f_name,
        arg_names,
        configs
      )
      when is_atom(f_name) and is_list(arg_names) and is_list(configs) do
    arg_names2 = Keyword.keys(configs)

    arg_names
    |> Kernel.==(arg_names2)
    |> if(
      do: :ok,
      else:
        (
          diff_names = (arg_names -- arg_names2) ++ (arg_names2 -- arg_names)
          msg = "
          >> #{f_name} function:
          >> there are some args that not found configs.
          >> have a try to check #{inspect(diff_names)} args."

          raise Argx.Error, msg
        )
    )
  end

  def are_keys_equal!(_f_name, _arg_names, _configs), do: raise(Argx.Error, "data type error")
end
