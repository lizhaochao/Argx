defmodule NestedMapTest do
  @moduledoc false

  use ExUnit.Case

  describe "map" do
    defmodule NestedMapA do
      use Argx, Project.Argx.Nested.Map.Shared
      def get(params), do: match(params, [OneRule])
    end

    test "ok" do
      args_map = %{one: %{a: "a", b: "b"}}
      args_keyword = [one: %{a: "a", b: "b"}]
      assert args_map == NestedMapA.get(args_map)
      assert args_keyword == NestedMapA.get(args_keyword)
    end

    test "error" do
      args_map = %{one: %{}}
      args_keyword = [one: %{}]
      assert [lacked: ["one:a", "one:b"]] == NestedMapA.get(args_map)
      assert [lacked: ["one:a", "one:b"]] == NestedMapA.get(args_keyword)

      args_map = %{one: %{a: 1, b: nil}}
      args_keyword = [one: %{a: 1, b: []}]
      assert [{:error_type, ["one:a"]}, {:lacked, ["one:b"]}] == NestedMapA.get(args_map)
      assert [error_type: ["one:a", "one:b"]] == NestedMapA.get(args_keyword)
    end
  end

  describe "map -> map" do
    defmodule NestedMapB do
      use Argx, Project.Argx.Nested.Map.Shared
      def get(params), do: match(params, [TwoRule])
    end

    test "ok" do
      args_map = %{one: %{z: %{a: "a", b: "b"}}}
      args_keyword = [one: %{z: %{a: "a", b: "b"}}]
      assert args_map == NestedMapB.get(args_map)
      assert args_keyword == NestedMapB.get(args_keyword)
    end

    test "error" do
      args_map = %{one: %{}}
      args_keyword = [one: %{}]
      assert [lacked: ["one:z"]] == NestedMapB.get(args_map)
      assert [lacked: ["one:z"]] == NestedMapB.get(args_keyword)

      args_map = %{one: %{z: %{a: 1, b: nil}}}
      args_keyword = [one: %{z: %{a: 1, b: []}}]
      assert [{:error_type, ["one:z:a"]}, {:lacked, ["one:z:b"]}] == NestedMapB.get(args_map)
      assert [error_type: ["one:z:a", "one:z:b"]] == NestedMapB.get(args_keyword)
    end
  end

  describe "map -> map -> map" do
    defmodule NestedMapC do
      use Argx, Project.Argx.Nested.Map.Shared
      def get(params), do: match(params, [ThreeRule])
    end

    test "ok" do
      args_map = %{one: %{y: %{z: %{a: "a", b: "b"}}}}
      args_keyword = [one: %{y: %{z: %{a: "a", b: "b"}}}]
      assert args_map == NestedMapC.get(args_map)
      assert args_keyword == NestedMapC.get(args_keyword)
    end

    test "error" do
      args_map = %{one: %{}}
      args_keyword = [one: %{}]
      assert [lacked: ["one:y"]] == NestedMapC.get(args_map)
      assert [lacked: ["one:y"]] == NestedMapC.get(args_keyword)

      args_map = %{one: %{y: %{z: %{a: 1, b: nil}}}}
      args_keyword = [one: %{y: %{z: %{a: 1, b: []}}}]
      assert [{:error_type, ["one:y:z:a"]}, {:lacked, ["one:y:z:b"]}] == NestedMapC.get(args_map)
      assert [error_type: ["one:y:z:a", "one:y:z:b"]] == NestedMapC.get(args_keyword)
    end
  end

  describe "map -> list -> map" do
    defmodule NestedMapD do
      use Argx, Project.Argx.Nested.Map.Shared
      def get(params), do: match(params, [ListRuleA])
    end

    test "ok" do
      args_map = %{one: %{a: "a", b: [%{a: "a", b: "b"}, %{a: "aa", b: "bb"}]}}
      args_keyword = [one: %{a: "a", b: [%{a: "a", b: "b"}]}]
      assert args_map == NestedMapD.get(args_map)
      assert args_keyword == NestedMapD.get(args_keyword)
    end

    test "error" do
      args_map = %{one: %{}}
      args_keyword = [one: %{}]
      assert [lacked: ["one:a", "one:b"]] == NestedMapD.get(args_map)
      assert [lacked: ["one:a", "one:b"]] == NestedMapD.get(args_keyword)

      args_map = %{one: %{a: "a", b: [%{a: 1, b: nil}, %{a: nil, b: 2}]}}
      args_keyword = [one: %{a: %{}}]

      assert [error_type: ["one:b:1:a", "one:b:2:b"], lacked: ["one:b:1:b", "one:b:2:a"]] ==
               NestedMapD.get(args_map)

      assert [{:error_type, ["one:a"]}, {:lacked, ["one:b"]}] == NestedMapD.get(args_keyword)
    end
  end

  describe "map -> list -> integer" do
    defmodule NestedMapE do
      use Argx, Project.Argx.Nested.Map.Shared
      def get(params), do: match(params, [ListRuleB])
    end

    test "ok" do
      args_map = %{one: %{a: "a", b: [1, 2, 3]}}
      args_keyword = [one: %{a: "a", b: [1, 2, 3]}]
      assert args_map == NestedMapE.get(args_map)
      assert args_keyword == NestedMapE.get(args_keyword)
    end

    test "error" do
      args_map = %{one: %{}}
      args_keyword = [one: %{}]
      assert [lacked: ["one:a", "one:b"]] == NestedMapE.get(args_map)
      assert [lacked: ["one:a", "one:b"]] == NestedMapE.get(args_keyword)

      args_map = %{one: %{a: "a", b: [nil, "a", 1, "a"]}}
      args_keyword = [one: %{a: "a", b: [nil, nil]}]
      assert [error_type: ["one:b:2", "one:b:4"], lacked: ["one:b:1"]] == NestedMapE.get(args_map)
      assert [lacked: ["one:b:1", "one:b:2"]] == NestedMapE.get(args_keyword)
    end
  end

  describe "string key: map -> map -> map" do
    defmodule NestedMapF do
      use Argx, Project.Argx.Nested.Map.Shared
      def get(params), do: match(params, [ThreeRule])
    end

    test "ok" do
      args_map = %{"one" => %{"y" => %{"z" => %{"a" => "a", "b" => "b"}}}}
      args_keyword = [one: %{"y" => %{"z" => %{"a" => "a", "b" => "b"}}}]
      assert %{one: %{y: %{z: %{a: "a", b: "b"}}}} == NestedMapF.get(args_map)
      assert [one: %{y: %{z: %{a: "a", b: "b"}}}] == NestedMapF.get(args_keyword)
    end

    test "error" do
      args_map = %{one: %{}}
      args_keyword = [one: %{}]
      assert [lacked: ["one:y"]] == NestedMapF.get(args_map)
      assert [lacked: ["one:y"]] == NestedMapF.get(args_keyword)

      args_map = %{"one" => %{"y" => %{"z" => %{"a" => 1, "b" => nil}}}}
      args_keyword = [one: %{y: %{"z" => %{"a" => 1, "b" => []}}}]
      assert [{:error_type, ["one:y:z:a"]}, {:lacked, ["one:y:z:b"]}] == NestedMapF.get(args_map)
      assert [error_type: ["one:y:z:a", "one:y:z:b"]] == NestedMapF.get(args_keyword)
    end
  end
end

defmodule Project.Argx.Nested.Map.Shared do
  @moduledoc false

  use Argx.Defconfig

  ### map type
  defconfig(OneRule, [one({:map, SimpleMapRule})])
  defconfig(TwoRule, [one({:map, MapRule})])
  defconfig(ThreeRule, [one({:map, Rule})])

  defconfig(Rule, [y({:map, MapRule})])
  defconfig(MapRule, [z({:map, SimpleMapRule})])
  defconfig(SimpleMapRule, [a(:string), b(:string)])

  ###
  defconfig(ListRuleA, [one({:map, RuleA})])
  defconfig(ListRuleB, [one({:map, RuleB})])
  defconfig(RuleA, [a(:string), b({:list, SimpleMapRule})])
  defconfig(RuleB, [a(:string), b({:list, IntegerRule})])
  defconfig(IntegerRule, [_(:integer)])

  def fmt_errors({:error, errors}), do: errors
  def fmt_errors(new_args), do: new_args
end
