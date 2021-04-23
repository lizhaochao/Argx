defmodule ProjectC do
  @moduledoc false

  use Argx

  defconfig(MapRule, [y(:string), z(:integer, 1..10)])
  defconfig(MapRule2, [a(:string), b(:integer), c({:list, MapRule2})])
  defconfig(ListRule, _(:integer, :auto))

  defconfig(OneRule, one({:list, MapRule}))
  defconfig(TwoRule, two({:list, MapRule2}))
  defconfig(ThreeRule, three({:list, ListRule}))

  def get1(params), do: match(params, [OneRule])
  def get2(params), do: match(params, [TwoRule])
  def get3(params), do: match(params, [ThreeRule])

  def fmt_errors({:error, _} = errors), do: errors
  def fmt_errors(new_args), do: new_args
end

defmodule NestedTest do
  @moduledoc false

  use ExUnit.Case

  alias Argx.Formatter

  describe "list" do
    test "error - nested map" do
      list_data = [
        %{y: 21, z: nil},
        %{y: 22, z: "bb"},
        %{y: 22, z: 11}
      ]

      args = %{one: list_data}

      expected =
        {:error,
         [
           error_type: ["one:1:y", "one:2:y", "one:2:z", "one:3:y"],
           lacked: ["one:1:z"],
           out_of_range: ["one:3:z"]
         ]}

      assert expected == args |> ProjectC.get1() |> Formatter.reverse_errors()
    end

    test "ok - nested map" do
      list_data = [
        %{y: "aa", z: 1},
        %{y: "bb", z: 2}
      ]

      expected_args = %{one: list_data}
      assert expected_args == ProjectC.get1(expected_args)
    end

    test "ok - more fields" do
      list_data = [
        %{y: "aa", z: 1},
        %{y: "ab", z: 2}
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
