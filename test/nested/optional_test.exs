defmodule NestedOptionalTest do
  @moduledoc false

  use ExUnit.Case

  describe "one key" do
    defmodule NestedOptionalA do
      use Argx, Project.Argx.Nested.Optional.Shared
      def get(params), do: match(params, [OptionalA])
    end

    test "ok" do
      args_map = %{a: nil}
      args_keyword = [a: nil]
      assert args_map == NestedOptionalA.get(args_map)
      assert args_keyword == NestedOptionalA.get(args_keyword)

      args_map = %{}
      args_keyword = []
      assert args_map == NestedOptionalA.get(args_map)
      assert args_keyword == NestedOptionalA.get(args_keyword)
    end
  end

  describe "two key" do
    defmodule NestedOptionalB do
      use Argx, Project.Argx.Nested.Optional.Shared
      def get(params), do: match(params, [OptionalB])
    end

    test "ok" do
      args_map = %{a: "a", b: nil}
      args_keyword = [a: "a", b: nil]
      assert args_map == NestedOptionalB.get(args_map)
      assert args_keyword == NestedOptionalB.get(args_keyword)

      args_map = %{a: "a"}
      args_keyword = [a: "a"]
      assert args_map == NestedOptionalB.get(args_map)
      assert args_keyword == NestedOptionalB.get(args_keyword)
    end

    test "error" do
      args_map = %{}
      args_keyword = []
      assert [lacked: [:a]] == NestedOptionalB.get(args_map)
      assert [lacked: [:a]] == NestedOptionalB.get(args_keyword)
    end
  end

  describe "list -> map" do
    defmodule NestedOptionalC do
      use Argx, Project.Argx.Nested.Optional.Shared
      def get(params), do: match(params, [RuleA])
    end

    test "ok" do
      args_map = %{one: [%{a: "a", b: nil}]}
      args_keyword = [one: [%{a: "a", b: nil}]]
      assert args_map == NestedOptionalC.get(args_map)
      assert args_keyword == NestedOptionalC.get(args_keyword)

      args_map = %{one: [%{a: "a"}]}
      args_keyword = [one: [%{a: "a"}]]
      assert args_map == NestedOptionalC.get(args_map)
      assert args_keyword == NestedOptionalC.get(args_keyword)

      args_map = %{one: [%{a: "a", b: nil}, %{a: "aa", b: nil}]}
      args_keyword = [one: [%{a: "a", b: nil}, %{a: "aa", b: nil}]]
      assert args_map == NestedOptionalC.get(args_map)
      assert args_keyword == NestedOptionalC.get(args_keyword)

      args_map = %{one: [%{a: "a"}, %{a: "aa"}]}
      args_keyword = [one: [%{a: "a"}, %{a: "aa"}]]
      assert args_map == NestedOptionalC.get(args_map)
      assert args_keyword == NestedOptionalC.get(args_keyword)
    end

    test "error" do
      args_map = %{one: [%{}]}
      args_keyword = [one: [%{}]]
      assert [lacked: ["one:1:a"]] == NestedOptionalC.get(args_map)
      assert [lacked: ["one:1:a"]] == NestedOptionalC.get(args_keyword)

      args_map = %{one: []}
      args_keyword = [one: []]
      assert [lacked: ["one:a"]] == NestedOptionalC.get(args_map)
      assert [lacked: ["one:a"]] == NestedOptionalC.get(args_keyword)

      args_map = %{one: nil}
      args_keyword = [one: nil]
      assert [lacked: [:one]] == NestedOptionalC.get(args_map)
      assert [lacked: [:one]] == NestedOptionalC.get(args_keyword)
    end
  end

  describe "list -> map -> list - map" do
    defmodule NestedOptionalD do
      use Argx, Project.Argx.Nested.Optional.Shared
      def get(params), do: match(params, [RuleB])
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

defmodule Project.Argx.Nested.Optional.Shared do
  @moduledoc false

  use Argx.Defconfig

  defconfig(RuleA, [one({:list, OptionalB})])
  defconfig(RuleB, [one({:list, ListRule})])

  defconfig(ListRule, [z({:list, OptionalB})])

  defconfig(OptionalA, [a(:string, :optional)])
  defconfig(OptionalB, [a(:string), b(:string, :optional)])

  def fmt_errors({:error, errors}), do: errors
  def fmt_errors(new_args), do: new_args
end
