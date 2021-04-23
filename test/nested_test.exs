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

  def fmt_errors({:error, _} = errors), do: errors
  def fmt_errors(new_args), do: new_args
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

      expected_args = %{one: list_data}
      assert expected_args == ProjectC.get(expected_args)
    end

    test "more fields" do
      list_data = [
        %{a: "aa", b: 21, c: 3.31},
        %{a: "ab", b: 22, c: 3.32}
      ]

      expected_args = %{one: list_data}
      args = Map.put(expected_args, :two, 2.2)
      assert expected_args == ProjectC.get(args)
    end
  end

  describe "error" do
    test "empty map" do
      assert {:error, [lacked: [:one]]} == ProjectC.get(%{oen: nil})
    end
  end
end
