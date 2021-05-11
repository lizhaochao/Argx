defmodule Argx.Checker do
  @moduledoc false

  import Argx.Error

  alias Argx.{Const, Parser}
  alias Argx.Checker.Is

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
        {arg_name2, %Argx.Config{optional: false, empty: true}} = config,
        path,
        errors,
        path_handler
      )
      when arg_name == arg_name2 do
    if empty?(arg_value) do
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
         {arg_name2, %Argx.Config{range: range}},
         path,
         path_handler
       )
       when arg_name == arg_name2 do
    if in_range?(arg_value, Parser.parse_range(range)) do
      errors
    else
      errors
      |> reduce_errors(arg_name, path, path_handler, :out_of_range)
      |> out_of_range(path, path_handler)
    end
  end

  ###
  def are_keys_equal!(
        f_name,
        arg_names,
        configs
      )
      when is_atom(f_name) and is_list(arg_names) and is_map(configs) do
    arg_names2 = configs |> Map.keys() |> Enum.sort()

    arg_names
    |> Enum.sort()
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

  ###
  def empty?(term), do: Is.empty?(term)

  def some_type?(term, :integer), do: is_integer(term)
  def some_type?(term, :float), do: is_float(term)
  def some_type?(term, :string), do: is_bitstring(term)
  def some_type?(term, :list), do: is_list(term)
  def some_type?(term, :map), do: is_map(term)
  def some_type?(term, :boolean), do: is_boolean(term)
  def some_type?(_term, _other_type), do: false

  def in_range?(term, range), do: Is.in_range?(term, range)
end
