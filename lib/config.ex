defmodule Argx.Config do
  @moduledoc false

  import Argx.Util

  alias Argx.Const

  @enforce_keys [:type, :optional, :auto, :range, :default, :empty, :nested]
  defstruct @enforce_keys

  def get_defconfigs(m) when is_atom(m) do
    :functions
    |> m.__info__()
    |> Enum.filter(fn {f_name, _arity} ->
      f_name |> to_string() |> Kernel.=~(to_string(Const.defconfigs_key()))
    end)
    |> Enum.reduce(%{}, fn {f_name, _arity}, general_configs ->
      configs = apply(m, f_name, [])
      Map.merge(general_configs, configs)
    end)
  end

  def get_defconfigs(_other_m), do: %{}

  def get_configs_by_modules([_ | _] = modules) do
    modules
    |> Enum.reduce(%{}, fn m, configs ->
      defconfigs = get_defconfigs(m)
      Map.merge(configs, defconfigs)
    end)
  end

  def get_configs_by_modules(_other_modules), do: %{}

  def get_configs_by_names(%{} = all_configs, [_ | _] = names) do
    names
    |> prune_names()
    |> Enum.reduce(%{}, fn name, name_configs ->
      new_configs = drill_down(all_configs, name)
      Map.merge(name_configs, new_configs)
    end)
  end

  def get_configs_by_names(_other_all_configs, _other_names), do: %{}

  defp drill_down(all_configs, name) do
    configs = fetch_by_name(all_configs, name)

    do_drill_down(
      configs,
      all_configs,
      Enum.into(configs, [])
    )
  end

  defp do_drill_down(new_config, _all_configs, []) do
    new_config
  end

  defp do_drill_down(
         new_config,
         all_configs,
         [{_field, %Argx.Config{nested: nil}} | rest]
       ) do
    do_drill_down(new_config, all_configs, rest)
  end

  defp do_drill_down(
         new_config,
         all_configs,
         [{field, %Argx.Config{nested: nested_name} = map_value} | rest]
       ) do
    nested_configs = drill_down(all_configs, nested_name)
    new_config = put_nested(new_config, field, map_value, nested_configs)
    do_drill_down(new_config, all_configs, rest)
  end

  defp put_nested(%{} = config, key, %Argx.Config{} = value, %{} = nested_configs) do
    Map.put(
      config,
      key,
      Map.put(value, :nested, nested_configs)
    )
  end

  defp fetch_by_name(%{} = configs, name) when is_atom(name) do
    configs
    |> Map.fetch(name)
    |> case do
      {:ok, config} -> config
      :error -> raise(Argx.Error, "not found config by #{name}")
    end
  end
end

defmodule Argx.Error do
  @moduledoc false

  import Argx.Util

  alias Argx.Const

  defexception message: nil

  def reduce_errors(errors, key, path, path_handler, check_type) do
    with new_path <- path_handler.(key, path),
         new_errors <- append(new_path, errors, check_type) do
      {new_errors, nil, nil}
    end
  end

  ###
  def merge_errors(left, right) when is_list(left) and is_list(right) do
    with left_errors <- left |> pre_errors() |> Enum.sort(),
         right_errors <- right |> pre_errors() |> Enum.sort() do
      do_merger_errors([], left_errors, right_errors)
    end
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

  ###
  def sort_errors([_ | _] = errors) do
    sorted_errors =
      errors
      |> Enum.sort()
      |> Enum.map(fn {type, fields} ->
        {type, Enum.sort(fields)}
      end)

    {:error, sorted_errors}
  end

  def sort_errors({:error, errors}), do: sort_errors(errors)
  def sort_errors([] = errors), do: errors
end
