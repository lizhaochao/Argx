defmodule Argx.Checker.DSL do
  @moduledoc false

  alias Argx.{Const, Error}

  @allowed_fun_types Const.allowed_fun_types()
  @configs_keyword Const.configs_keyword()

  ### Argx
  def check_args!(%{} = _args), do: :ignore

  def check_args!(args) when is_list(args) do
    args
    |> Keyword.keyword?()
    |> if(
      do: :ignore,
      else: raise(Error, "args must be map or keyword")
    )
  end

  def check_args!(_other_args), do: raise(Error, "args must be map or keyword")

  def check_config_names!(config_names) do
    case config_names do
      [_ | _] -> :ignore
      _ -> raise Error, "config names must be list & not empty"
    end
  end

  ### with check macro
  def check!(configs, block) do
    with :ok <- check_configs(configs),
         :ok = ok <- check_block(block) do
      ok
    else
      :configs_error -> raise Error, "not found #{@configs_keyword} keyword"
      :block_error -> raise Error, "unknown function type"
      :block_empty_error -> raise Error, "required one function at least"
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
  def check_defconfig!(_name, [_ | _] = configs), do: do_check_defconfig!(configs)
  def check_defconfig!(_name, {_, _, _} = config), do: do_check_defconfig!([config])
  def check_defconfig!(_name, [] = config), do: do_check_defconfig!(config)

  def do_check_defconfig!(term) do
    case term do
      {f, _, [_ | _]} when f != :__aliases__ -> :ok
      [{:||, _, [{_, _, _} = config, _]} | _] -> do_check_defconfig!(config)
      [{_, _, _} = config | _] -> do_check_defconfig!(config)
      _ -> Error.syntax_error(term)
    end
  end
end
