defmodule Argx.Parser do
  @moduledoc false

  @allowed_fun_types [:def, :defp]

  ###
  def parse_fun(block) do
    block |> _parse_fun(%{})
  end

  defp _parse_fun({type, _, fun}, acc) when type in @allowed_fun_types do
    fun |> _parse_fun(acc)
  end

  defp _parse_fun([{:when, _, fa_guard}, [{:do, block}]], acc) do
    fa_guard
    |> _parse_fun(acc)
    |> Map.put(:block, block)
  end

  defp _parse_fun([fa, [{:do, block}]], acc) do
    fa
    |> _parse_fun(acc)
    |> Map.put(:block, block)
    |> Map.put(:guard, true)
  end

  defp _parse_fun([fa, guard], acc) do
    fa
    |> _parse_fun(acc)
    |> Map.put(:guard, guard)
  end

  defp _parse_fun({f, _, [{_, _, nil} | _] = a}, acc) do
    acc
    |> Map.put(:f, f)
    |> Map.put(:a, a)
  end

  defp _parse_fun({f, _, nil}, acc) do
    acc
    |> Map.put(:f, f)
    |> Map.put(:a, [])
  end

  defp _parse_fun(_, _) do
    nil
  end

  ###
  def parse_configs(configs, acc \\ nil)

  def parse_configs([config | rest], nil) do
    acc = %{} |> Map.merge(config_rule(config))
    rest |> parse_configs(acc)
  end

  def parse_configs({:configs, _, [config | rest]}, nil) do
    acc = %{} |> Map.merge(config_rule(config))
    rest |> parse_configs(acc)
  end

  def parse_configs(config, nil) do
    %{} |> Map.merge(config_rule(config))
  end

  def parse_configs([config | rest], acc) do
    acc = acc |> Map.merge(config_rule(config, acc))
    rest |> parse_configs(acc)
  end

  def parse_configs([], acc) do
    acc
  end

  def parse_configs(_, _) do
    nil
  end

  defp config_rule(config, acc \\ nil)

  defp config_rule({:__aliases__, _, [name]}, acc) do
    names = (acc && acc |> Map.get(:__names__)) || []
    %{:__names__ => [name | names]}
  end

  defp config_rule({field, _, config}, _acc) do
    %{field => config}
  end

  defp config_rule(_, _) do
    %{}
  end

  ###
  def parse_defconfig_name({:__aliases__, _, [name]}) do
    name
  end

  def parse_defconfig_name(_) do
    :ignore
  end
end
