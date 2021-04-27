defmodule NestedListTest do
  @moduledoc false

  use ExUnit.Case

  describe "list -> map" do
    defmodule NestedListA do
      use Argx, Project.Argx.Nested.Shared
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
    end
  end

  describe "list -> map -> list - map" do
    defmodule NestedListB do
      use Argx, Project.Argx.Nested.Shared
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
    end
  end

  describe "list -> map -> list - map - list" do
    defmodule NestedListC do
      use Argx, Project.Argx.Nested.Shared
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
    end
  end
end

defmodule Project.Argx.Nested.Shared do
  @moduledoc false

  use Argx.Defconfig

  ### Optional
  defconfig(OptionalRuleA, [a(:string, :optional)])

  ### Nested
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
