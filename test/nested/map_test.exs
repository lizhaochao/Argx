defmodule NestedMapTest do
  @moduledoc false

  use ExUnit.Case

  describe "map -> map -> map" do
    defmodule NestedMapC do
      use Argx, share: Project.Argx.Nested.Map.Shared
      def get(params), do: check(params, [OneRule])
    end

    test "ok" do
      args_map = %{one: %{a: %{b: "b", c: "c"}}}
      args_keyword = [one: %{a: %{b: "b", c: "c"}}]
      assert args_map == NestedMapC.get(args_map)
      assert args_keyword == NestedMapC.get(args_keyword)
    end

    test "error" do
      args_map = %{one: %{}}
      assert [lacked: ["one:a"]] == NestedMapC.get(args_map)

      args_map = %{one: %{a: %{b: 1, c: nil}}}
      assert [error_type: ["one:a:b"], lacked: ["one:a:c"]] == NestedMapC.get(args_map)
    end
  end

  describe "string key: map -> map -> map" do
    defmodule NestedMapF do
      use Argx, share: Project.Argx.Nested.Map.Shared
      def get(params), do: check(params, [OneRule])
    end

    test "ok" do
      args_map = %{"one" => %{"a" => %{"b" => "b", "c" => "c"}}}
      assert %{one: %{a: %{b: "b", c: "c"}}} == NestedMapF.get(args_map)
    end

    test "error" do
      args_map = %{"one" => %{"a" => %{"b" => 1, "c" => nil}}}
      assert [error_type: ["one:a:b"], lacked: ["one:a:c"]] == NestedMapF.get(args_map)
    end
  end
end

defmodule Project.Argx.Nested.Map.Shared do
  @moduledoc false

  use Argx.Defconfig

  defconfig(OneRule, [one({:map, Rule})])
  defconfig(Rule, [a({:map, SimpleMapRule})])
  defconfig(SimpleMapRule, [b(:string), c(:string)])

  def fmt_errors({:error, errors}), do: errors
  def fmt_errors(new_args), do: new_args
end
