defmodule Argx.Config do
  @moduledoc false

  @enforce_keys [:type, :optional, :auto, :range, :default, :empty, :nested]
  defstruct @enforce_keys

  def get_defconfigs(m, f_name_keyword) when is_atom(m) do
    :functions
    |> m.__info__()
    |> Enum.filter(fn {f_name, _arity} ->
      f_name |> to_string() |> Kernel.=~(to_string(f_name_keyword))
    end)
    |> Enum.reduce(%{}, fn {f_name, _arity}, shared_configs ->
      configs = apply(m, f_name, [])
      Map.merge(shared_configs, configs)
    end)
  end

  def get_defconfigs(_other_m, _f_name_keyword), do: %{}

  def get_configs_by_modules([_ | _] = modules, f_name_keyword) do
    modules
    |> Enum.reduce(%{}, fn m, configs ->
      defconfigs = get_defconfigs(m, f_name_keyword)
      Map.merge(configs, defconfigs)
    end)
  end

  def get_configs_by_modules(_other_modules, _f_name_keyword), do: %{}

  def get_configs_by_names(warn, max_depth) do
    fn
      %{} = configs, [_ | _] = names ->
        names
        |> distinct()
        |> Enum.reduce(%{}, fn name, name_configs ->
          new_configs = drill_down(configs, name, warn, 1, max_depth)
          Map.merge(name_configs, new_configs)
        end)

      _other_configs, _other_names ->
        %{}
    end
  end

  defp drill_down(all_configs, name, warn, depth, max_depth) do
    with _ <- warn_by_depth(name, warn, depth, max_depth),
         configs <- fetch_by_name(all_configs, name),
         configs_kw <- Enum.into(configs, []) do
      do_drill_down(configs, all_configs, configs_kw, warn, depth, max_depth)
    end
  end

  defp do_drill_down(new_config, _all_configs, [], _warn, _depth, _max_depth), do: new_config

  defp do_drill_down(
         new_config,
         all_configs,
         [{_field, %Argx.Config{nested: nil}} | rest],
         warn,
         depth,
         max_depth
       ) do
    do_drill_down(new_config, all_configs, rest, warn, depth, max_depth)
  end

  defp do_drill_down(
         new_config,
         all_configs,
         [{field, %Argx.Config{nested: nested_name} = map_value} | rest],
         warn,
         depth,
         max_depth
       ) do
    with nested_configs <- drill_down(all_configs, nested_name, warn, depth + 1, max_depth),
         new_config <- put_nested(new_config, field, map_value, nested_configs) do
      do_drill_down(new_config, all_configs, rest, warn, depth, max_depth)
    end
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

  defp distinct([_ | _] = term), do: term |> MapSet.new() |> MapSet.to_list()
  defp distinct(other), do: other

  defp warn_by_depth(name, warn, depth, max_depth) do
    with true <- warn,
         true <- depth > max_depth,
         ":" <> name <- inspect(name) do
      IO.warn("#{name} config's nested depth is #{depth}.", [])
      :ok
    else
      _ -> :ignore
    end
  end
end
