defmodule ConverterTest do
  @moduledoc false

  use ExUnit.Case

  alias Argx.Converter, as: C

  ###
  describe "convert - ok" do
    test "integer" do
      args = [total: "3"]

      configs = [
        total: %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: nil,
          optional: false
        }
      ]

      assert [total: 3] == C.convert(args, configs)
    end

    test "float" do
      args = [weight: "3.21"]

      configs = [
        weight: %Argx.Config{
          type: :float,
          auto: true,
          range: nil,
          default: nil,
          optional: false
        }
      ]

      assert [weight: 3.21] == C.convert(args, configs)
    end

    test "integer & float" do
      args = [total: "3", weight: "3.21"]

      configs = [
        total: %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: nil,
          optional: false
        },
        weight: %Argx.Config{
          type: :float,
          auto: true,
          range: nil,
          default: nil,
          optional: false
        }
      ]

      assert [total: 3, weight: 3.21] == C.convert(args, configs)
    end
  end

  describe "convert - error" do
    test "should be in the same order" do
      args = [weight: "3.21", total: "3"]

      configs = [
        total: %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: nil,
          optional: false
        },
        weight: %Argx.Config{
          type: :float,
          auto: true,
          range: nil,
          default: nil,
          optional: false
        }
      ]

      assert_raise Argx.Error, fn ->
        C.convert(args, configs)
      end
    end

    test "args is empty" do
      args = []

      configs = [
        total: %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: nil,
          optional: false
        }
      ]

      assert_raise Argx.Error, fn ->
        C.convert(args, configs)
      end
    end

    test "configs is empty" do
      args = [total: "3"]
      configs = []

      assert_raise Argx.Error, fn ->
        C.convert(args, configs)
      end
    end
  end

  ###
  describe "to_type - integer" do
    test "integer to integer" do
      assert -1 === C.to_type(-1, :integer)
      assert 0 === C.to_type(0, :integer)
      assert 1 === C.to_type(1, :integer)
    end

    test "string to integer" do
      assert -1 === C.to_type("-1", :integer)
      assert 0 === C.to_type("0", :integer)
      assert 1 === C.to_type("1", :integer)
    end
  end

  describe "to_type - float" do
    test "float to float" do
      assert -1.0 === C.to_type(-1.0, :float)
      assert 0.0 === C.to_type(0.0, :float)
      assert 1.0 === C.to_type(1.0, :float)

      assert -1.1 === C.to_type(-1.1, :float)
      assert 0.1 === C.to_type(0.1, :float)
      assert 1.1 === C.to_type(1.1, :float)
    end

    test "integer to float" do
      assert -1.0 === C.to_type(-1, :float)
      assert 0.0 === C.to_type(0, :float)
      assert 1.0 === C.to_type(1, :float)
    end

    test "string to float" do
      assert -1.0 === C.to_type("-1", :float)
      assert 0.0 === C.to_type("0", :float)
      assert 1.0 === C.to_type("1", :float)

      assert -1.0 === C.to_type("-1.0", :float)
      assert 0.0 === C.to_type("0.0", :float)
      assert 1.0 === C.to_type("1.0", :float)

      assert -1.1 === C.to_type("-1.1", :float)
      assert 0.1 === C.to_type("0.1", :float)
      assert 1.1 === C.to_type("1.1", :float)
    end
  end

  describe "to_type - boolean" do
    test "boolean" do
      assert true === C.to_type(true, :boolean)
      assert false === C.to_type(false, :boolean)
      assert true === C.to_type(1, :boolean)
      assert false === C.to_type(0, :boolean)
      assert true === C.to_type("1", :boolean)
      assert false === C.to_type("0", :boolean)
    end
  end

  describe "to_type - other type" do
    test "string" do
      assert "" === C.to_type("", :string)
      assert "string" === C.to_type("string", :string)
      assert "string" === C.to_type("string", :list)
    end

    test "list" do
      assert [] === C.to_type([], :list)
      assert [1, 2, 3] === C.to_type([1, 2, 3], :list)
      assert [1, 2, 3] === C.to_type([1, 2, 3], :string)
    end

    test "map" do
      assert %{} === C.to_type(%{}, :map)
      assert %{a: 1, b: 2} === C.to_type(%{a: 1, b: 2}, :map)
      assert %{"a" => 1, "b" => 2} === C.to_type(%{"a" => 1, "b" => 2}, :map)

      assert %{a: 1, b: 2} === C.to_type(%{a: 1, b: 2}, :string)
      assert %{"a" => 1, "b" => 2} === C.to_type(%{"a" => 1, "b" => 2}, :string)
    end
  end
end
