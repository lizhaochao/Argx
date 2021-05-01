defmodule ConverterTest do
  use ExUnit.Case

  alias Argx.Converter, as: C

  ###
  describe "convert - ok" do
    test "integer" do
      arg = {:total, "3"}

      config = {
        :total,
        %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: nil
        }
      }

      assert {:total, 3} == C.convert(arg, config)
    end

    test "float" do
      arg = {:weight, "3.21"}

      config = {
        :weight,
        %Argx.Config{
          type: :float,
          auto: true,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: nil
        }
      }

      assert {:weight, 3.21} == C.convert(arg, config)
    end
  end

  describe "convert - error" do
    test "arg is empty" do
      arg = {}

      config = {
        :total,
        %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: nil
        }
      }

      assert_raise Argx.Error, fn ->
        C.convert(arg, config)
      end
    end

    test "config is empty" do
      arg = {:total, "3"}
      config = {:total, %{}}

      assert_raise Argx.Error, fn ->
        C.convert(arg, config)
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
