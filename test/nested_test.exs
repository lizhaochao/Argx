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

defmodule NestedOptionalTest do
  @moduledoc false

  use ExUnit.Case

  describe "one key" do
    defmodule NestedOptionalA do
      use Argx, Project.Argx.Nested.Shared
      def get(params), do: match(params, [OptionalRuleA])
    end

    test "one key" do
      args = %{a: nil}
      assert args == NestedOptionalA.get(args)

      args = %{}
      assert args == NestedOptionalA.get(args)
    end
  end

  describe "two key" do
    defmodule NestedOptionalB do
      use Argx, Project.Argx.Nested.Shared
      def get(params), do: match(params, [OptionalRuleB])
    end

    test "two key" do
      args = %{a: "a", b: nil}
      assert args == NestedOptionalB.get(args)

      args = %{a: "a"}
      assert args == NestedOptionalB.get(args)
    end
  end

  describe "list -> map" do
    defmodule NestedOptionalC do
      use Argx, Project.Argx.Nested.Shared
      def get(params), do: match(params, [FourRule])
    end

    test "ok" do
      args = %{one: [%{a: "a", b: nil}]}
      assert args == NestedOptionalC.get(args)

      args = %{one: [%{a: "a"}]}
      assert args == NestedOptionalC.get(args)

      args = %{one: [%{a: "a", b: nil}, %{a: "aa", b: nil}]}
      assert args == NestedOptionalC.get(args)

      args = %{one: [%{a: "a"}, %{a: "aa"}]}
      assert args == NestedOptionalC.get(args)
    end

    test "error" do
      args = %{one: [%{}]}
      assert [lacked: ["one:1:a"]] == NestedOptionalC.get(args)

      args = %{one: []}
      assert [lacked: ["one:a"]] == NestedOptionalC.get(args)

      args = %{one: nil}
      assert [lacked: [:one]] == NestedOptionalC.get(args)
    end
  end

  describe "list -> map -> list - map" do
    defmodule NestedOptionalD do
      use Argx, Project.Argx.Nested.Shared
      def get(params), do: match(params, [FiveRule])
    end

    test "ok" do
      args = %{one: [%{z: [%{a: "a", b: nil}]}]}
      assert args == NestedOptionalD.get(args)

      args = %{one: [%{z: [%{a: "a"}]}]}
      assert args == NestedOptionalD.get(args)

      args = %{one: [%{z: [%{a: "a", b: nil}, %{a: "a", b: nil}]}]}
      assert args == NestedOptionalD.get(args)

      args = %{one: [%{z: [%{a: "a"}, %{a: "a"}]}]}
      assert args == NestedOptionalD.get(args)
    end

    test "error" do
      args = %{one: [%{z: [%{}]}]}
      assert [lacked: ["one:1:z:1:a"]] == NestedOptionalD.get(args)

      args = %{one: [%{}]}
      assert [lacked: ["one:1:z"]] == NestedOptionalD.get(args)

      args = %{one: []}
      assert [lacked: ["one:z"]] == NestedOptionalD.get(args)

      args = %{one: nil}
      assert [lacked: [:one]] == NestedOptionalD.get(args)
    end
  end
end

defmodule Project.Argx.Nested.Shared do
  @moduledoc false

  use Argx.Defconfig

  ### Optional
  defconfig(OptionalRuleA, [a(:string, :optional)])
  defconfig(OptionalRuleB, [a(:string), b(:string, :optional)])

  ### Nested
  defconfig(OneRule, [one({:list, SimpleMapRule})])
  defconfig(TwoRule, [one({:list, SimpleListRule})])
  defconfig(ThreeRule, [one({:list, ListRule})])
  defconfig(FourRule, [one({:list, OptionalRuleB})])
  defconfig(FiveRule, [one({:list, ListOptionalRule})])

  defconfig(SimpleMapRule, [a(:string)])
  defconfig(SimpleListRule, [z({:list, SimpleMapRule})])
  defconfig(MapRule, [a({:list, SimpleMapRule})])
  defconfig(ListRule, [z({:list, MapRule})])
  defconfig(ListOptionalRule, [z({:list, OptionalRuleB})])

  def fmt_errors({:error, errors}), do: errors
  def fmt_errors(new_args), do: new_args
end
