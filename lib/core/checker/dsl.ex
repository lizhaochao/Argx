defmodule Argx.Checker.DSL do
  @moduledoc false

  alias Argx.Const

  @allowed_fun_types Const.allowed_fun_types()
  @configs_keyword Const.configs_keyword()

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
end
