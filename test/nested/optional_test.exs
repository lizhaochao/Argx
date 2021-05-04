defmodule NestedOptionalTest do
  @moduledoc false

  use ExUnit.Case

  describe "two key" do
    defmodule NestedOptionalA do
      use Argx, share: Project.Argx.Nested.Optional.Shared
      def get(params), do: check(params, [OptionalB])
    end

    test "ok" do
      args_map = %{a: "a", b: nil}
      args_keyword = [a: "a", b: nil]
      assert args_map == NestedOptionalA.get(args_map)
      assert args_keyword == NestedOptionalA.get(args_keyword)

      args_map = %{a: "a"}
      args_keyword = [a: "a"]
      assert args_map == NestedOptionalA.get(args_map)
      assert args_keyword == NestedOptionalA.get(args_keyword)
    end

    test "error" do
      args_map = %{}
      args_keyword = []
      assert [lacked: [:a]] == NestedOptionalA.get(args_map)
      assert [lacked: [:a]] == NestedOptionalA.get(args_keyword)
    end
  end

  describe "list -> map -> list - map" do
    defmodule NestedOptionalB do
      use Argx, share: Project.Argx.Nested.Optional.Shared
      def get(params), do: check(params, [Rule])
    end

    test "ok" do
      args = %{one: [%{z: [%{a: "a", b: nil}]}]}
      assert args == NestedOptionalB.get(args)

      args = %{one: [%{z: [%{a: "a"}]}]}
      assert args == NestedOptionalB.get(args)

      args = %{one: [%{z: [%{a: "a", b: nil}, %{a: "a", b: nil}]}]}
      assert args == NestedOptionalB.get(args)

      args = %{one: [%{z: [%{a: "a"}, %{a: "a"}]}]}
      assert args == NestedOptionalB.get(args)
    end

    test "error" do
      args = %{one: [%{z: [%{}]}]}
      assert [lacked: ["one:1:z:1:a"]] == NestedOptionalB.get(args)

      args = %{one: [%{}]}
      assert [lacked: ["one:1:z"]] == NestedOptionalB.get(args)

      args = %{one: []}
      assert [lacked: ["one:z"]] == NestedOptionalB.get(args)

      args = %{one: nil}
      assert [lacked: [:one]] == NestedOptionalB.get(args)
    end
  end
end

defmodule Project.Argx.Nested.Optional.Shared do
  @moduledoc false

  use Argx.Defconfig

  defconfig(Rule, [one({:list, ListRule})])
  defconfig(ListRule, [z({:list, OptionalB})])
  defconfig(OptionalB, [a(:string), b(:string, :optional)])

  def fmt_errors({:error, errors}), do: errors
  def fmt_errors(new_args), do: new_args
end
