defmodule Argx.Config do
  @moduledoc false

  import Argx.Util

  alias Argx.Const

  @warn_max_nested_depth Const.warn_max_nested_depth()
  @defconfigs_key Const.defconfigs_key()

  @enforce_keys [:type, :optional, :auto, :range, :default, :empty, :nested]
  defstruct @enforce_keys

  def get_defconfigs(m) when is_atom(m) do
    :functions
    |> m.__info__()
    |> Enum.filter(fn {f_name, _arity} ->
      f_name |> to_string() |> Kernel.=~(to_string(@defconfigs_key))
    end)
    |> Enum.reduce(%{}, fn {f_name, _arity}, shared_configs ->
      configs = apply(m, f_name, [])
      Map.merge(shared_configs, configs)
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

  def get_configs_by_names(%{} = all_configs, [_ | _] = names, warn) do
    names
    |> prune_names()
    |> Enum.reduce(%{}, fn name, name_configs ->
      new_configs = drill_down(all_configs, name, 1, warn)
      Map.merge(name_configs, new_configs)
    end)
  end

  def get_configs_by_names(_other_all_configs, _other_names, _warn), do: %{}

  defp drill_down(all_configs, name, depth, warn) do
    with _ <- warn_by_depth(name, depth, @warn_max_nested_depth, warn),
         configs <- fetch_by_name(all_configs, name),
         configs_kw <- Enum.into(configs, []) do
      do_drill_down(configs, all_configs, configs_kw, depth, warn)
    end
  end

  defp do_drill_down(new_config, _all_configs, [], _depth, _warn), do: new_config

  defp do_drill_down(
         new_config,
         all_configs,
         [{_field, %Argx.Config{nested: nil}} | rest],
         depth,
         warn
       ) do
    do_drill_down(new_config, all_configs, rest, depth, warn)
  end

  defp do_drill_down(
         new_config,
         all_configs,
         [{field, %Argx.Config{nested: nested_name} = map_value} | rest],
         depth,
         warn
       ) do
    with nested_configs <- drill_down(all_configs, nested_name, depth + 1, warn),
         new_config <- put_nested(new_config, field, map_value, nested_configs) do
      do_drill_down(new_config, all_configs, rest, depth, warn)
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

  defp warn_by_depth(name, depth, max, warn) do
    with true <- warn,
         true <- depth >= max,
         ":" <> name <- inspect(name) do
      IO.warn("#{name} config's depth is #{depth}.", [])
      :ok
    else
      _ -> :ignore
    end
  end
end
