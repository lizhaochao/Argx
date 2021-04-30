defmodule UtilTest do
  @moduledoc false

  use ExUnit.Case

  alias Argx.Util, as: U

  test "prune names - normal atom" do
    assert :test == U.prune_names(:test)
  end

  test "prune names - with Elixir atom" do
    assert :YesCar == U.prune_names(YesCar)
  end
end
