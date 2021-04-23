defmodule ProjectC do
  @moduledoc false

  use Argx

  defconfig(MapRule, [y(:string), z(:integer, 1..10)])
  defconfig(MapRule2, [a(:string), b(:integer), c({:list, MapRule})])
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
    test "error - 1 level nested list" do
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

    test "error - 2 level nested list" do
      list_data = [
        %{
          a: 22,
          b: "str",
          c: [
            %{y: 1.1, z: 99},
            %{y: nil, z: "str"}
          ]
        },
        %{
          a: nil,
          b: nil,
          c: [
            %{y: %{}, z: "str"},
            %{y: 2.2, z: 88}
          ]
        }
      ]

      args = %{two: list_data}

      expected =
        {:error,
         [
           error_type: [
             "two:1:a",
             "two:1:b",
             "two:1:c:1:y",
             "two:1:c:2:z",
             "two:2:c:1:y",
             "two:2:c:1:z",
             "two:2:c:2:y"
           ],
           lacked: ["two:1:c:2:y", "two:2:a", "two:2:b"],
           out_of_range: ["two:1:c:1:z", "two:2:c:2:z"]
         ]}

      assert expected == args |> ProjectC.get2() |> Formatter.reverse_errors()
    end

    test "ok - 1 level nested list" do
      list_data = [
        %{y: "yy", z: 2},
        %{y: "yy", z: 2},
        %{y: "yy", z: 2}
      ]

      args = %{one: list_data}
      assert args == ProjectC.get1(args)
    end

    test "ok - 2 level nested list" do
      list_data = [
        %{
          a: "aa",
          b: 1,
          c: [
            %{y: "yy", z: 2}
          ]
        },
        %{
          a: "aa",
          b: 1,
          c: [
            %{y: "yy", z: 2}
          ]
        }
      ]

      args = %{two: list_data}
      assert args == ProjectC.get2(args)
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
