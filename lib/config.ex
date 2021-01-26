defmodule Argx.Config do
  @moduledoc false

  import Argx.Parser
  alias Argx.Config, as: C

  def do_defconfig(name, configs) do
    name = parse_defconfig_name(name)
    configs = parse_configs(configs)
    attr = %{name => configs}

    quote do
      Module.register_attribute(__MODULE__, :defconfig, accumulate: true)
      Module.put_attribute(__MODULE__, :defconfig, unquote(Macro.escape(attr)))
    end
  end

  def gen_configs(configs) do
    quote do
      defconfigs = Module.get_attribute(__MODULE__, unquote(:defconfig)) |> C.list_to_map()

      configs = unquote(Macro.escape(parse_configs(configs)))

      name_configs =
        defconfigs &&
          configs
          |> Map.get(:__names__)
          |> C.get_configs_by_names(defconfigs)

      (name_configs &&
         configs
         |> Map.merge(name_configs)
         |> Map.delete(:__names__)) || %{}
    end
  end

  ###
  def get_configs_by_names(_names, nil) do
    %{}
  end

  def get_configs_by_names(nil, _defconfigs) do
    %{}
  end

  def get_configs_by_names(names, defconfigs) do
    names
    |> Enum.reduce(%{}, fn name, acc ->
      config = defconfigs |> Map.get(name, nil)
      (config && acc |> Map.merge(config)) || acc
    end)
  end

  def list_to_map(nil) do
    %{}
  end

  def list_to_map(list) do
    list
    |> Enum.reduce(%{}, fn item, acc ->
      map =
        item
        |> Enum.reduce(nil, fn {k, v}, _ ->
          %{k => v}
        end)

      acc |> Map.merge(map)
    end)
  end
end
