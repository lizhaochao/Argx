defmodule ProjectC do
  @moduledoc false

  use Argx

  defconfig(MapRule2, [x(:string), z(:integer)])
  defconfig(MapRule, [a(:string), b(:integer), c({:list, MapRule2})])
  defconfig(OneRule, one({:list, MapRule}))
  defconfig(TwoRule, two({:list, MapRule}))
  defconfig(ThreeRule, three(:float))

  def get(params) do
    match(params, [OneRule])
  end

  def fmt_errors([]), do: :ok
  def fmt_errors(errors), do: :error
end

defmodule NestedTest do
  @moduledoc false

  use ExUnit.Case

  describe "ok" do
    test "ok" do
      list_data = [
        %{a: "aa", b: 21, c: 3.31},
        %{a: "ab", b: 22, c: 3.32}
      ]

      assert :ok == ProjectC.get(%{one: list_data})
    end

    test "more fields" do
      list_data = [
        %{a: "aa", b: 21, c: 3.31},
        %{a: "ab", b: 22, c: 3.32}
      ]

      assert :ok == ProjectC.get(%{one: list_data, two: 2.2})
    end
  end

  describe "error" do
    test "empty map" do
      assert :error == ProjectC.get(%{oen: "str"})
    end
  end
end
