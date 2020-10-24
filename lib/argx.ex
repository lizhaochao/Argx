defmodule Argx do
  @moduledoc false

  import Const
  import Utils
  import Parser

  def validate(input, config) do
    input
    |> m_to_kw()
    |> go_though(config, [])
    |> parse_result(:simple)
  end

  defp go_though([{k, v} | remain], config, path) do
    changed_config =
      k
      |> get_arg_definition_by_key(config, path)
      |> definition()
      |> set_result_by_key(path)
      |> drill_down(v, path ++ [k])

    remain |> go_though(changed_config || config, path)
  end

  defp go_though([], config, _) do
    config
  end

  # drill down
  defp drill_down(nil, _, _) do
    nil
  end

  defp drill_down(config, [], _) do
    config
  end

  defp drill_down(config, [item | _remain], path) do
    item
    |> go_though(config, path ++ drill_down_path())
  end

  defp drill_down(config, _, _) do
    config
  end

  # -
  defp get_arg_definition_by_key(key, config, path) do
    definition = config |> get_in(path ++ [key])
    {definition, config, key}
  end

  defp definition({nil, _, _}) do
    nil
  end

  defp definition({_, _, _} = resp) do
    resp
  end

  defp set_result_by_key(nil, _) do
    nil
  end

  defp set_result_by_key({_, config, key}, path) do
    set_key = path ++ [key]
    get_key = [[result_key()] ++ set_key]

    config
    |> get_in_result_by_key(get_key)
    |> put_in_result_by_key(config, set_key)
  end

  defp get_in_result_by_key(config, key) do
    config |> get_in(key)
  end

  defp put_in_result_by_key(nil, config, key) do
    result =
      config
      |> get_in([result_key()])
      |> Map.put(key, [true])

    config
    |> put_in([result_key()], result)
  end

  defp put_in_result_by_key([_] = result, config, key) do
    config |> put_in(key, result ++ [true])
  end
end
