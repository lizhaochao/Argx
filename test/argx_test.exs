defmodule ArgxTest do
  use ExUnit.Case
  doctest Argx

  test "greets the argx" do
    assert Argx.hello() == :argx
  end
end
