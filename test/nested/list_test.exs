defmodule NestedListTest do
  @moduledoc false

  use ExUnit.Case

  describe "list -> map -> list -> map -> list -> map" do
    defmodule NestedListC do
      use Argx, share: Project.Argx.Nested.List.Shared
      def get(params), do: check(params, [Rule])
    end

    test "ok" do
      args_map = %{
        one: [
          %{z: [%{a: [%{a: "a"}, %{a: "aa"}]}, %{a: [%{a: "a"}, %{a: "aa"}]}]},
          %{z: [%{a: [%{a: "a"}, %{a: "aa"}]}, %{a: [%{a: "a"}, %{a: "aa"}]}]}
        ]
      }

      args_keyword = [
        one: [
          %{z: [%{a: [%{a: "a"}, %{a: "aa"}]}, %{a: [%{a: "a"}, %{a: "aa"}]}]},
          %{z: [%{a: [%{a: "a"}, %{a: "aa"}]}, %{a: [%{a: "a"}, %{a: "aa"}]}]}
        ]
      ]

      assert args_map == NestedListC.get(args_map)
      assert args_keyword == NestedListC.get(args_keyword)
    end

    test "error" do
      args_map = %{one: [%{z: [%{a: [%{}]}]}]}
      assert [lacked: ["one:1:z:1:a:1:a"]] == NestedListC.get(args_map)

      args_map = %{one: [%{z: [%{}]}]}
      assert [lacked: ["one:1:z:1:a"]] == NestedListC.get(args_map)

      args_map = %{one: [%{z: nil}]}
      assert [lacked: ["one:1:z"]] == NestedListC.get(args_map)

      args_map = %{one: []}
      assert [lacked: ["one:z"]] == NestedListC.get(args_map)

      args_map = %{}
      assert [lacked: [:one]] == NestedListC.get(args_map)

      # one record in list
      args_keyword = [one: [%{z: [%{a: [%{a: nil}, %{a: 1}]}]}]]

      assert [{:error_type, ["one:1:z:1:a:2:a"]}, {:lacked, ["one:1:z:1:a:1:a"]}] ==
               NestedListC.get(args_keyword)
    end
  end

  describe "list -> integer" do
    defmodule NestedListAA do
      use Argx, share: Project.Argx.Nested.List.Shared
      def get(params), do: check(params, [ValueRule])
    end

    test "ok" do
      args_map = %{one: [1, 2, 3, 4]}
      assert args_map == NestedListAA.get(args_map)

      args_map = %{one: []}
      assert args_map == NestedListAA.get(args_map)
    end

    test "auto" do
      args_map = %{one: ["1", "2", "3", "4"]}
      assert %{one: [1, 2, 3, 4]} == NestedListAA.get(args_map)
    end

    test "error" do
      args_map = %{one: ["1", nil]}
      assert [lacked: ["one:2"]] == NestedListAA.get(args_map)

      args_map = %{one: [nil, "a"]}
      assert [{:error_type, ["one:2"]}, {:lacked, ["one:1"]}] == NestedListAA.get(args_map)
    end
  end
end

defmodule Project.Argx.Nested.List.Shared do
  @moduledoc false

  use Argx.Defconfig

  ### value type
  defconfig(ValueRule, [one({:list, IntegerRule})])
  defconfig(IntegerRule, [_(:integer, :auto)])

  ### list type
  defconfig(Rule, [one({:list, ListRule})])
  defconfig(ListRule, [z({:list, MapRule})])
  defconfig(MapRule, [a({:list, SimpleMapRule})])
  defconfig(SimpleMapRule, [a(:string)])

  def fmt_errors({:error, errors}), do: errors
  def fmt_errors(new_args), do: new_args
end
