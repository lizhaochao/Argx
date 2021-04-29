defmodule NestedListTest do
  @moduledoc false

  use ExUnit.Case

  describe "list -> map" do
    defmodule NestedListA do
      use Argx, share: Project.Argx.Nested.List.Shared
      def get(params), do: match(params, [OneRule])
    end

    test "ok" do
      # one record in list
      args_map = %{one: [%{a: "a"}]}
      args_keyword = [one: [%{a: "a"}]]
      assert args_map == NestedListA.get(args_map)
      assert args_keyword == NestedListA.get(args_keyword)

      # two records in list
      args_map = %{one: [%{a: "a"}, %{a: "aa"}]}
      args_keyword = [one: [%{a: "a"}, %{a: "aa"}]]
      assert args_map == NestedListA.get(args_map)
      assert args_keyword == NestedListA.get(args_keyword)
    end

    test "error" do
      args_map = %{one: [%{}]}
      args_keyword = [one: [%{}]]
      assert [lacked: ["one:1:a"]] == NestedListA.get(args_map)
      assert [lacked: ["one:1:a"]] == NestedListA.get(args_keyword)

      args_map = %{one: nil}
      args_keyword = [one: nil]
      assert [lacked: [:one]] == NestedListA.get(args_map)
      assert [lacked: [:one]] == NestedListA.get(args_keyword)

      # one record in list
      args_map = %{one: [%{a: 1}, %{a: nil}]}
      assert [error_type: ["one:1:a"], lacked: ["one:2:a"]] == NestedListA.get(args_map)
    end
  end

  describe "list -> map -> list - map" do
    defmodule NestedListB do
      use Argx, share: Project.Argx.Nested.List.Shared
      def get(params), do: match(params, [TwoRule])
    end

    test "ok" do
      # one record in list
      args_map = %{one: [%{z: [%{a: "a"}]}]}
      args_keyword = [one: [%{z: [%{a: "a"}]}]]
      assert args_map == NestedListB.get(args_map)
      assert args_keyword == NestedListB.get(args_keyword)

      # two records in list
      args_map = %{one: [%{z: [%{a: "a"}, %{a: "aa"}]}, %{z: [%{a: "aaa"}, %{a: "aaaa"}]}]}
      args_keyword = [one: [%{z: [%{a: "a"}, %{a: "aa"}]}, %{z: [%{a: "aaa"}, %{a: "aaaa"}]}]]
      assert args_map == NestedListB.get(args_map)
      assert args_keyword == NestedListB.get(args_keyword)
    end

    test "error" do
      args_map = %{one: [%{z: [%{}]}]}
      args_keyword = [one: [%{z: [%{}]}]]
      assert [lacked: ["one:1:z:1:a"]] == NestedListB.get(args_map)
      assert [lacked: ["one:1:z:1:a"]] == NestedListB.get(args_keyword)

      args_map = %{one: [%{z: nil}]}
      args_keyword = [one: [%{z: nil}]]
      assert [lacked: ["one:1:z"]] == NestedListB.get(args_map)
      assert [lacked: ["one:1:z"]] == NestedListB.get(args_keyword)

      args_map = %{one: []}
      args_keyword = [one: []]
      assert [lacked: ["one:z"]] == NestedListB.get(args_map)
      assert [lacked: ["one:z"]] == NestedListB.get(args_keyword)

      args_map = %{}
      args_keyword = []
      assert [lacked: [:one]] == NestedListB.get(args_map)
      assert [lacked: [:one]] == NestedListB.get(args_keyword)

      # two records in list
      args_map = %{one: [%{z: [%{a: "a"}, %{a: 1}]}, %{z: [%{a: nil}, %{a: "aaaa"}]}]}
      assert [error_type: ["one:1:z:2:a"], lacked: ["one:2:z:1:a"]] == NestedListB.get(args_map)
    end
  end

  describe "list -> map -> list - map - list" do
    defmodule NestedListC do
      use Argx, share: Project.Argx.Nested.List.Shared
      def get(params), do: match(params, [ThreeRule])
    end

    test "ok" do
      # one record in list
      args_map = %{one: [%{z: [%{a: [%{a: "a"}]}]}]}
      args_keyword = [one: [%{z: [%{a: [%{a: "a"}]}]}]]
      assert args_map == NestedListC.get(args_map)
      assert args_keyword == NestedListC.get(args_keyword)

      # two records in list
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
      args_keyword = [one: [%{z: [%{a: [%{}]}]}]]
      assert [lacked: ["one:1:z:1:a:1:a"]] == NestedListC.get(args_map)
      assert [lacked: ["one:1:z:1:a:1:a"]] == NestedListC.get(args_keyword)

      args_map = %{one: [%{z: [%{}]}]}
      args_keyword = [one: [%{z: [%{}]}]]
      assert [lacked: ["one:1:z:1:a"]] == NestedListC.get(args_map)
      assert [lacked: ["one:1:z:1:a"]] == NestedListC.get(args_keyword)

      args_map = %{one: [%{z: nil}]}
      args_keyword = [one: [%{z: nil}]]
      assert [lacked: ["one:1:z"]] == NestedListC.get(args_map)
      assert [lacked: ["one:1:z"]] == NestedListC.get(args_keyword)

      args_map = %{one: []}
      args_keyword = [one: []]
      assert [lacked: ["one:z"]] == NestedListC.get(args_map)
      assert [lacked: ["one:z"]] == NestedListC.get(args_keyword)

      args_map = %{}
      args_keyword = []
      assert [lacked: [:one]] == NestedListC.get(args_map)
      assert [lacked: [:one]] == NestedListC.get(args_keyword)

      # one record in list
      args_keyword = [one: [%{z: [%{a: [%{a: nil}, %{a: 1}]}]}]]

      assert [{:error_type, ["one:1:z:1:a:2:a"]}, {:lacked, ["one:1:z:1:a:1:a"]}] ==
               NestedListC.get(args_keyword)
    end
  end

  describe "list -> integer" do
    defmodule NestedListAA do
      use Argx, share: Project.Argx.Nested.List.Shared
      def get(params), do: match(params, [ListIntegerRule])
    end

    test "ok" do
      args_map = %{one: [1, 2, 3, 4]}
      args_keyword = [one: [1, 2, 3, 4]]
      assert args_map == NestedListAA.get(args_map)
      assert args_keyword == NestedListAA.get(args_keyword)

      args_map = %{one: []}
      args_keyword = [one: []]
      assert args_map == NestedListAA.get(args_map)
      assert args_keyword == NestedListAA.get(args_keyword)
    end

    test "auto" do
      args_map = %{one: ["1", "2", "3", "4"]}
      args_keyword = [one: ["1", 2, "3", 4]]
      assert %{one: [1, 2, 3, 4]} == NestedListAA.get(args_map)
      assert [one: [1, 2, 3, 4]] == NestedListAA.get(args_keyword)
    end

    test "error" do
      args_map = %{one: ["1", nil]}
      args_keyword = [one: ["1", 2, "3", nil]]
      assert [lacked: ["one:2"]] == NestedListAA.get(args_map)
      assert [lacked: ["one:4"]] == NestedListAA.get(args_keyword)

      args_map = %{one: [nil, "a"]}
      args_keyword = [one: ["1", nil, "3", "a"]]
      assert [{:error_type, ["one:2"]}, {:lacked, ["one:1"]}] == NestedListAA.get(args_map)
      assert [{:error_type, ["one:4"]}, {:lacked, ["one:2"]}] == NestedListAA.get(args_keyword)
    end
  end

  describe "list -> float" do
    defmodule NestedListAB do
      use Argx, share: Project.Argx.Nested.List.Shared
      def get(params), do: match(params, [ListFloatRule])
    end

    test "ok" do
      args_map = %{one: [1.1, 2.1, 3.1, 4.1]}
      args_keyword = [one: [1.1, 2.1, 3.1, 4.1]]
      assert args_map == NestedListAB.get(args_map)
      assert args_keyword == NestedListAB.get(args_keyword)

      args_map = %{one: []}
      args_keyword = [one: []]
      assert args_map == NestedListAB.get(args_map)
      assert args_keyword == NestedListAB.get(args_keyword)
    end

    test "auto" do
      args_map = %{one: ["1", "2", "3", "4"]}
      args_keyword = [one: ["1", 2, "3", 4]]
      assert %{one: [1.0, 2.0, 3.0, 4.0]} == NestedListAB.get(args_map)
      assert [one: [1.0, 2, 3.0, 4]] == NestedListAB.get(args_keyword)
    end

    test "error" do
      args_map = %{one: ["1", nil]}
      args_keyword = [one: ["1", 2, "3", nil]]
      assert [lacked: ["one:2"]] == NestedListAB.get(args_map)
      assert [lacked: ["one:4"]] == NestedListAB.get(args_keyword)

      args_map = %{one: [nil, "a"]}
      args_keyword = [one: ["1", nil, "3", "a"]]
      assert [{:error_type, ["one:2"]}, {:lacked, ["one:1"]}] == NestedListAB.get(args_map)
      assert [{:error_type, ["one:4"]}, {:lacked, ["one:2"]}] == NestedListAB.get(args_keyword)
    end
  end
end

defmodule Project.Argx.Nested.List.Shared do
  @moduledoc false

  use Argx.Defconfig

  ### auto
  defconfig(IntegerRule, [_(:integer, :auto)])
  defconfig(FloatRule, [_(:float, :auto)])

  ### value type
  defconfig(ListIntegerRule, [one({:list, IntegerRule})])
  defconfig(ListFloatRule, [one({:list, FloatRule})])

  ### list type
  defconfig(OneRule, [one({:list, SimpleMapRule})])
  defconfig(TwoRule, [one({:list, SimpleListRule})])
  defconfig(ThreeRule, [one({:list, ListRule})])

  defconfig(SimpleMapRule, [a(:string)])
  defconfig(SimpleListRule, [z({:list, SimpleMapRule})])
  defconfig(MapRule, [a({:list, SimpleMapRule})])
  defconfig(ListRule, [z({:list, MapRule})])

  def fmt_errors({:error, errors}), do: errors
  def fmt_errors(new_args), do: new_args
end
