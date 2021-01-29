defmodule Argx.Config do
  @moduledoc false

  import Argx.Parser

  alias Argx.Config, as: C

  @store_key :defconfig_key

  def do_defconfig(name, configs) do
    name = parse_defconfig_name(name)
    configs = parse_configs(configs)
    attr = %{name => configs}

    quote do
      Module.register_attribute(__MODULE__, unquote(@store_key), accumulate: true)
      Module.put_attribute(__MODULE__, unquote(@store_key), unquote(Macro.escape(attr)))
    end
  end

  def gen_configs(configs) do
    quote do
      defconfigs = Module.get_attribute(__MODULE__, unquote(@store_key)) |> C.list_to_map()
      configs = unquote(configs |> parse_configs() |> Macro.escape())
      {names, configs} = Map.pop(configs, :__names__)

      names
      |> C.get_configs_by_names(defconfigs)
      |> Map.merge(configs)
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
      acc |> Map.merge(item)
    end)
  end
end
