defmodule Argx.Matcher do
  @moduledoc false

  import Argx.{Checker, Converter, Defaulter, Util}

  def match(m, f, [_ | _] = args_kw, %{} = configs) when is_atom(m) and is_atom(f) do
    f |> are_keys_equal!(args_kw, configs)

    configs = args_kw |> Keyword.keys() |> sort_by_keys(configs)

    args_kw
    |> set_default(configs, m)
    |> convert(configs, m)
    |> Keyword.values()
  end
end
