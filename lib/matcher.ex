defmodule Argx.Matcher do
  @moduledoc false

  alias Argx.{Checker, Converter, Defaulter, Parser, Util}

  def match(m, f, [{_arg_name, _arg_value} | _] = args, %{} = configs)
      when is_atom(m) and is_atom(f) do
    Checker.are_keys_equal!(f, args, configs)

    configs =
      args
      |> Keyword.keys()
      |> Util.sort_by_keys(configs)

    args =
      args
      |> Defaulter.set_default(configs, m)
      |> Converter.convert(configs)

    {[], args, configs}
    |> lacked()
    |> drop_checked_keys(args, configs)
    |> error_type()
    |> drop_checked_keys(args, configs)
    |> out_of_range()
    |> post_match(args)
  end

  def match(_, _, _, _), do: :match_error

  ###
  defp lacked({errors, args, configs}), do: do_lacked(errors, args, configs)

  defp do_lacked([], [], []), do: []

  defp do_lacked(errors, [], []), do: {:error, errors}

  defp do_lacked(
         errors,
         [{arg_name, nil} | arg_rest],
         [{arg_name2, %Argx.Config{optional: false}} | config_rest]
       )
       when arg_name == arg_name2 do
    errors
    |> reduce_errors(:lacked, arg_name)
    |> do_lacked(arg_rest, config_rest)
  end

  defp do_lacked(
         errors,
         [{arg_name, arg_value} | arg_rest],
         [{arg_name2, %Argx.Config{optional: false, type: type, empty: true}} | config_rest]
       )
       when arg_name == arg_name2 do
    arg_value
    |> Checker.empty?(type)
    |> if(
      do: reduce_errors(errors, :lacked, arg_name),
      else: errors
    )
    |> do_lacked(arg_rest, config_rest)
  end

  defp do_lacked(
         errors,
         [{arg_name, _} | arg_rest],
         [{arg_name2, _} | config_rest]
       )
       when arg_name == arg_name2 do
    do_lacked(errors, arg_rest, config_rest)
  end

  ###
  defp error_type({errors, args, configs}), do: do_error_type(errors, args, configs)

  defp do_error_type([], [], []), do: []

  defp do_error_type(errors, [], []), do: {:error, errors}

  defp do_error_type(
         errors,
         [{arg_name, nil} | arg_rest],
         [{arg_name2, %Argx.Config{optional: true}} | config_rest]
       )
       when arg_name == arg_name2 do
    do_error_type(errors, arg_rest, config_rest)
  end

  defp do_error_type(
         errors,
         [{arg_name, arg_value} | arg_rest],
         [{arg_name2, %Argx.Config{type: type}} | config_rest]
       )
       when arg_name == arg_name2 do
    arg_value
    |> Checker.some_type?(type)
    |> if(
      do: errors,
      else: reduce_errors(errors, :error_type, arg_name)
    )
    |> do_error_type(arg_rest, config_rest)
  end

  ###
  defp out_of_range({errors, args, configs}), do: do_out_of_range(errors, args, configs)

  defp do_out_of_range([], [], []), do: []

  defp do_out_of_range(errors, [], []), do: {:error, errors}

  defp do_out_of_range(
         errors,
         [{arg_name, nil} | arg_name],
         [{arg_name2, %Argx.Config{optional: true}} | config_rest]
       )
       when arg_name == arg_name2 do
    do_out_of_range(errors, arg_name, config_rest)
  end

  defp do_out_of_range(
         errors,
         [{arg_name, _} | arg_rest],
         [{arg_name2, %Argx.Config{range: nil}} | config_rest]
       )
       when arg_name == arg_name2 do
    do_out_of_range(errors, arg_rest, config_rest)
  end

  defp do_out_of_range(
         errors,
         [{arg_name, arg_value} | arg_rest],
         [{arg_name2, %Argx.Config{type: type, range: range}} | config_rest]
       )
       when arg_name == arg_name2 do
    arg_value
    |> Checker.in_range?(Parser.parse_range(range), type)
    |> if(
      do: errors,
      else: reduce_errors(errors, :out_of_range, arg_name)
    )
    |> do_out_of_range(arg_rest, config_rest)
  end

  ###
  defp reduce_errors(errors, check_type, field) do
    {nil, new_errors} =
      Keyword.get_and_update(errors, check_type, fn current ->
        new_value = (current && [field | current]) || [field]
        {nil, new_value}
      end)

    new_errors
  end

  defp drop_checked_keys([], args, configs), do: {[], args, configs}

  defp drop_checked_keys({:error, errors}, args, configs) do
    drop_checked_keys(errors, errors, args, configs)
  end

  defp drop_checked_keys([], errors, args, configs), do: {errors, args, configs}

  defp drop_checked_keys([{_check_type, keys} | rest], errors, args, configs) do
    args = Keyword.drop(args, keys)
    configs = Keyword.drop(configs, keys)
    drop_checked_keys(rest, errors, args, configs)
  end

  defp post_match({:error, errors}, _args) do
    errors =
      errors
      |> Enum.reverse()
      |> Enum.map(fn {type, fields} ->
        {type, Enum.reverse(fields)}
      end)

    {:error, errors}
  end

  defp post_match([], args), do: Keyword.values(args)
end
