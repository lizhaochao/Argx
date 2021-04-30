defmodule CheckerTest do
  @moduledoc false

  use ExUnit.Case

  alias Argx.Checker, as: C

  ###
  describe "check!" do
    test "block ok" do
      configs = quote do: configs(Rule)

      block =
        quote do
          def get(name) when is_bitstring(name) do
            name
          end

          def get(names) when is_list(names) do
            names
          end
        end

      result = C.check!(configs, block)
      assert :ok == result
    end
  end

  ###
  describe "some_type? - integer" do
    test "true" do
      [-1, 0, 1]
      |> Enum.each(fn integer ->
        assert C.some_type?(integer, :integer)
      end)
    end

    test "false" do
      [-1.0, -1.1, 0.0, 1.0, 1.1, "str", :atom, true, false, [1, 2], {1, 2}, %{a: 1}]
      |> Enum.each(fn not_integer ->
        refute C.some_type?(not_integer, :integer)
      end)
    end
  end

  describe "some_type? - float" do
    test "true" do
      [-1.0, -1.1, 0.0, 1.0, 1.1]
      |> Enum.each(fn float ->
        assert C.some_type?(float, :float)
      end)
    end

    test "false" do
      [-1, 0, 1, "str", :atom, true, false, [1, 2], {1, 2}, %{a: 1}]
      |> Enum.each(fn not_float ->
        refute C.some_type?(not_float, :float)
      end)
    end
  end

  describe "some_type? - string" do
    test "true" do
      ["", "str"]
      |> Enum.each(fn string ->
        assert C.some_type?(string, :string)
      end)
    end

    test "false" do
      [-1, 0, 1, -1.0, -1.1, 0.0, 1.0, 1.1, :atom, true, false, [1, 2], {1, 2}, %{a: 1}]
      |> Enum.each(fn not_string ->
        refute C.some_type?(not_string, :string)
      end)
    end
  end

  describe "some_type? - list" do
    test "true" do
      [[], 'abc', [1, 2, 3], ["1", "2", "3"]]
      |> Enum.each(fn list ->
        assert C.some_type?(list, :list)
      end)
    end

    test "false" do
      [-1, 0, 1, -1.0, -1.1, 0.0, 1.0, 1.1, "str", :atom, true, false, {1, 2}, %{a: 1}]
      |> Enum.each(fn not_list ->
        refute C.some_type?(not_list, :list)
      end)
    end
  end

  describe "some_type? - map" do
    defmodule Test.Struct, do: defstruct([])

    test "true" do
      [1..2, %{}, %{a: 1, b: 1}, %Test.Struct{}]
      |> Enum.each(fn map ->
        assert C.some_type?(map, :map)
      end)
    end

    test "false" do
      [-1, 0, 1, -1.0, -1.1, 0.0, 1.0, 1.1, "str", :atom, true, false, {1, 2}]
      |> Enum.each(fn not_map ->
        refute C.some_type?(not_map, :map)
      end)
    end
  end

  describe "some_type? - boolean" do
    test "true" do
      [true, false]
      |> Enum.each(fn map ->
        assert C.some_type?(map, :boolean)
      end)
    end

    test "false" do
      [-1, 0, 1, -1.0, -1.1, 0.0, 1.0, 1.1, "str", :atom, {1, 2}, %{}]
      |> Enum.each(fn not_map ->
        refute C.some_type?(not_map, :boolean)
      end)
    end
  end

  describe "some_type? - other" do
    test "false" do
      refute C.some_type?([1, 2, 3], :map)
      refute C.some_type?(%{a: 1}, :string)
      refute C.some_type?("string", :integer)
      refute C.some_type?(1.23, :list)
      refute C.some_type?(:argx, :float)
    end
  end

  ###
  describe "in_range? - integer" do
    test "true" do
      range = [1, 10]
      assert C.in_range?(1, range, :integer)
      assert C.in_range?(5, range, :integer)
      assert C.in_range?(10, range, :integer)

      range = [10, 10]
      assert C.in_range?(10, range, :integer)
    end

    test "false" do
      range = [1, 10]
      refute C.in_range?(0, range, :integer)
      refute C.in_range?(11, range, :integer)

      range = [10, 10]
      refute C.in_range?(5, range, :integer)
      refute C.in_range?(15, range, :integer)
    end
  end

  describe "in_range? - float" do
    test "true" do
      range = [1, 10]
      assert C.in_range?(1.0, range, :float)
      assert C.in_range?(1.5, range, :float)
      assert C.in_range?(5.5, range, :float)
      assert C.in_range?(9.5, range, :float)
      assert C.in_range?(10.0, range, :float)

      range = [10, 10]
      assert C.in_range?(10.0, range, :float)

      range = [10.5, 10.5]
      assert C.in_range?(10.5, range, :float)
    end

    test "false" do
      range = [1, 10]
      refute C.in_range?(0.9, range, :float)
      refute C.in_range?(10.5, range, :float)

      range = [10, 10]
      refute C.in_range?(5.0, range, :float)
      refute C.in_range?(15.0, range, :float)

      range = [10.5, 10.5]
      refute C.in_range?(5.5, range, :float)
      refute C.in_range?(15.5, range, :float)
    end
  end

  describe "in_range? - string" do
    test "true" do
      range = [1, 3]
      assert C.in_range?("a", range, :string)
      assert C.in_range?("aa", range, :string)
      assert C.in_range?("aaa", range, :string)

      range = [3, 3]
      assert C.in_range?("aaa", range, :string)
    end

    test "false" do
      range = [1, 3]
      refute C.in_range?("", range, :string)
      refute C.in_range?("aaaa", range, :string)

      range = [3, 3]
      refute C.in_range?("aa", range, :string)
      refute C.in_range?("aaaa", range, :string)
    end
  end

  describe "in_range? - list" do
    test "true" do
      range = [1, 3]
      assert C.in_range?([1], range, :list)
      assert C.in_range?([1, 2], range, :list)
      assert C.in_range?([1, 2, 3], range, :list)

      range = [3, 3]
      assert C.in_range?([1, 2, 3], range, :list)
    end

    test "false" do
      range = [1, 3]
      refute C.in_range?([], range, :list)
      refute C.in_range?([1, 2, 3, 4], range, :list)

      range = [3, 3]
      refute C.in_range?([1, 2], range, :list)
      refute C.in_range?([1, 2, 3, 4], range, :list)
    end
  end

  describe "in_range? - map" do
    test "true" do
      range = [1, 3]
      assert C.in_range?(%{a: 1}, range, :map)
      assert C.in_range?(%{a: 1, b: 2}, range, :map)
      assert C.in_range?(%{a: 1, b: 2, c: 3}, range, :map)

      range = [3, 3]
      assert C.in_range?(%{a: 1, b: 2, c: 3}, range, :map)
    end

    test "false" do
      range = [1, 3]
      refute C.in_range?(%{}, range, :map)
      refute C.in_range?(%{a: 1, b: 2, c: 3, d: 4}, range, :map)

      range = [3, 3]
      refute C.in_range?(%{a: 1, b: 2}, range, :map)
      refute C.in_range?(%{a: 1, b: 2, c: 3, d: 4}, range, :map)
    end
  end

  describe "in_range? - boolean" do
    test "true" do
      range = [1, 3]
      assert C.in_range?(true, range, :boolean)
      assert C.in_range?(false, range, :boolean)

      range = [3, 3]
      assert C.in_range?(true, range, :boolean)
      assert C.in_range?(false, range, :boolean)
    end

    test "false" do
      range = [1, 3]
      refute C.in_range?("true", range, :boolean)
      refute C.in_range?(1, range, :boolean)

      range = [3, 3]
      refute C.in_range?(1.23, range, :boolean)
      refute C.in_range?("false", range, :boolean)
    end
  end

  describe "in_range? - other" do
    test "false" do
      range = [1, 3]
      refute C.in_range?([1, 2, 3], range, :map)
      refute C.in_range?(%{a: 1}, range, :string)
      refute C.in_range?("string", range, :integer)
      refute C.in_range?(1.23, range, :list)
      refute C.in_range?(:argx, range, :float)
    end
  end

  ###
  describe "empty?" do
    test "true" do
      assert C.empty?(0, :integer)
      assert C.empty?(0.0, :float)
      assert C.empty?("", :string)
      assert C.empty?([], :list)
      assert C.empty?(%{}, :map)
    end

    test "false" do
      refute C.empty?(-1, :integer)
      refute C.empty?(1, :integer)
      refute C.empty?(-1.0, :float)
      refute C.empty?(1.0, :float)
      refute C.empty?("a", :string)
      refute C.empty?([1], :list)
      refute C.empty?(%{a: 1}, :map)
    end
  end

  ###
  describe "are_keys_equal!" do
    test "ok" do
      f_name = :get
      arg_names = [:a, :b]
      configs = [a: %{}, b: %{}]
      assert :ok == C.are_keys_equal!(f_name, arg_names, configs)
    end

    test "error" do
      f_name = :get
      arg_names = [:a, :b]
      configs = %{d: %{}, a: %{}}

      assert_raise Argx.Error, fn ->
        C.are_keys_equal!(f_name, arg_names, configs)
      end
    end
  end
end
