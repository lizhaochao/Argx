defmodule ProjectC do
  @moduledoc false

  use Argx

  defconfig(MapRule, [y(:string), z(:integer)])
  defconfig(MapRule2, [a(:string), b(:integer), c({:list, MapRule2})])
  defconfig(ListRule, _(:integer, :auto))

  defconfig(OneRule, one({:list, MapRule}))
  defconfig(TwoRule, two({:list, MapRule2}))
  defconfig(ThreeRule, three({:list, ListRule}))

  def get1(params) do
    match(params, [OneRule])
  end

  def get2(params) do
    match(params, [TwoRule])
  end

  def get3(params) do
    match(params, [ThreeRule])
  end

  def fmt_errors({:error, _} = errors), do: errors
  def fmt_errors(new_args), do: new_args
end

defmodule NestedTest do
  @moduledoc false

  use ExUnit.Case

  describe "list" do
    test "ok - nested map" do
      list_data = [
        %{y: 21, z: "aa"},
        %{y: 22, z: "bb"}
      ]

      expected_args = %{one: list_data}
      assert expected_args == ProjectC.get1(expected_args)
    end

    test "ok - nested integer" do
      list_data = [1, "2", "3"]
      expected_args = %{one: list_data}
      assert expected_args == ProjectC.get1(expected_args)
    end

    test "ok - more fields" do
      list_data = [
        %{y: "aa", z: 21},
        %{y: "ab", z: 22}
      ]

      expected_args = %{one: list_data}
      args = Map.put(expected_args, :two, 2.2)
      assert expected_args == ProjectC.get1(args)
    end
  end

  describe "error" do
    test "empty map" do
      assert {:error, [lacked: [:one]]} == ProjectC.get1(%{oen: nil})
    end
  end
end
