defmodule Test.DefaulterYesterday do
  @moduledoc false

  def yesterday_ts, do: 1_618_650_000
  def get_yesterday_ts, do: yesterday_ts()
  def get_yesterday_ts(precision), do: precision
end

defmodule DefaulterTest do
  @moduledoc false

  use ExUnit.Case

  alias Argx.Defaulter, as: D

  @fixed_curr_ts 1_618_653_110

  ###
  describe "set_default - ok" do
    test "value" do
      args = [total: nil]

      configs = [
        total: %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: 3,
          optional: false,
          empty: false,
          nested: nil
        }
      ]

      [total: total] = D.set_default(args, configs, __MODULE__)
      assert 3 == total
    end

    test "function in the current module" do
      args = [total: nil]
      fun_expr = quote do: get_curr_ts()

      configs = [
        total: %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: fun_expr,
          optional: false,
          empty: false,
          nested: nil
        }
      ]

      [total: total] = D.set_default(args, configs, __MODULE__)
      assert @fixed_curr_ts == total
    end

    test "function in the another module" do
      args = [total: nil]
      fun_expr = quote do: Test.DefaulterYesterday.get_yesterday_ts()

      configs = [
        total: %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: fun_expr,
          optional: false,
          empty: false,
          nested: nil
        }
      ]

      [total: total] = D.set_default(args, configs, __MODULE__)
      assert Test.DefaulterYesterday.yesterday_ts() == total
    end
  end

  describe "set_default - error" do
    test "should be in the same order" do
      args = [weight: "3.21", total: "3"]

      configs = [
        total: %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: 4.56,
          optional: false,
          empty: false,
          nested: nil
        },
        weight: %Argx.Config{
          type: :float,
          auto: true,
          range: nil,
          default: 7,
          optional: false,
          empty: false,
          nested: nil
        }
      ]

      assert_raise Argx.Error, fn ->
        D.set_default(args, configs, __MODULE__)
      end
    end

    test "args is empty" do
      args = []

      configs = [
        total: %Argx.Config{
          type: :integer,
          auto: true,
          range: nil,
          default: 7,
          optional: false,
          empty: false,
          nested: nil
        }
      ]

      assert_raise Argx.Error, fn ->
        D.set_default(args, configs, __MODULE__)
      end
    end

    test "configs is empty" do
      args = [total: "3"]
      configs = []

      assert_raise Argx.Error, fn ->
        D.set_default(args, configs, __MODULE__)
      end
    end
  end

  ###
  describe "get_default - value - input as output" do
    test "value - integer & float" do
      dont_care_m = nil
      assert -1 === D.get_default(-1, dont_care_m)
      assert 1 === D.get_default(1, dont_care_m)
      assert 0 === D.get_default(0, dont_care_m)
      assert -1.23 === D.get_default(-1.23, dont_care_m)
      assert 1.23 === D.get_default(1.23, dont_care_m)
    end

    test "value - other" do
      dont_care_m = nil
      assert "a" === D.get_default("a", dont_care_m)
      assert %{a: 1} === D.get_default(%{a: 1}, dont_care_m)
      assert [1, 2, 3] === D.get_default([1, 2, 3], dont_care_m)
      assert true === D.get_default(true, dont_care_m)
      assert nil === D.get_default(nil, dont_care_m)
      assert :"1-nil" === D.get_default(:"1-nil", dont_care_m)
    end
  end

  describe "get_default - function - arity is zero" do
    test "in the current module" do
      fun_expr = quote do: get_curr_ts()
      assert @fixed_curr_ts == D.get_default(fun_expr, __MODULE__)
      assert @fixed_curr_ts == D.get_default(fun_expr, DefaulterTest)
    end

    test "in the another module" do
      fun_expr = quote do: get_yesterday_ts()

      assert Test.DefaulterYesterday.yesterday_ts() ==
               D.get_default(fun_expr, Test.DefaulterYesterday)
    end
  end

  describe "get_default - error" do
    test "in the current module - function reference" do
      fun_expr = quote do: &get_curr_ts/0

      assert_raise Argx.Error, fn ->
        D.get_default(fun_expr, __MODULE__)
      end
    end

    test "anonymous function" do
      fun_expr1 = quote do: fn -> 123 end
      fun_expr2 = quote do: fn x -> {x} end

      assert_raise Argx.Error, fn ->
        D.get_default(fun_expr1, __MODULE__)
      end

      assert_raise Argx.Error, fn ->
        D.get_default(fun_expr2, __MODULE__)
      end
    end

    test "in the current module - arity is not zero" do
      fun_expr = quote do: get_curr_ts(:second)

      assert_raise Argx.Error, fn ->
        D.get_default(fun_expr, __MODULE__)
      end
    end

    test "in the another module - arity is not zero" do
      fun_expr = quote do: get_yesterday_ts(:second)

      assert_raise Argx.Error, fn ->
        D.get_default(fun_expr, Test.DefaulterYesterday)
      end
    end
  end

  ###
  def get_curr_ts, do: @fixed_curr_ts
  def get_curr_ts(precision), do: precision
end
