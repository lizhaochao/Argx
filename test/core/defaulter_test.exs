defmodule Test.DefaulterYesterday do
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
      arg = {:total, nil}

      config = {
        :total,
        %Argx.Config{
          type: :integer,
          autoconvert: true,
          default: 3,
          optional: false,
          empty: false
        }
      }

      {:total, total} = D.set_default(arg, config, __MODULE__)
      assert 3 == total
    end

    test "function in the current module" do
      arg = {:total, nil}
      fun_expr = quote do: get_curr_ts()

      config = {
        :total,
        %Argx.Config{
          type: :integer,
          autoconvert: true,
          default: fun_expr,
          optional: false,
          empty: false
        }
      }

      {:total, total} = D.set_default(arg, config, __MODULE__)
      assert @fixed_curr_ts == total
    end

    test "function in the another module" do
      arg = {:total, nil}
      fun_expr = quote do: Test.DefaulterYesterday.get_yesterday_ts()

      config = {
        :total,
        %Argx.Config{
          type: :integer,
          autoconvert: true,
          default: fun_expr,
          optional: false,
          empty: false
        }
      }

      {:total, total} = D.set_default(arg, config, __MODULE__)
      assert Test.DefaulterYesterday.yesterday_ts() == total
    end
  end

  describe "set_default - error" do
    test "should be in the same order" do
      arg = [weight: "3.21", total: "3"]

      config = [
        total: %Argx.Config{
          type: :integer,
          autoconvert: true,
          default: 4.56,
          optional: false,
          empty: false
        },
        weight: %Argx.Config{
          type: :float,
          autoconvert: true,
          default: 7,
          optional: false,
          empty: false
        }
      ]

      assert_raise Argx.Error, fn ->
        D.set_default(arg, config, __MODULE__)
      end
    end

    test "arg is empty" do
      arg = []

      config = [
        total: %Argx.Config{
          type: :integer,
          autoconvert: true,
          default: 7,
          optional: false,
          empty: false
        }
      ]

      assert_raise Argx.Error, fn ->
        D.set_default(arg, config, __MODULE__)
      end
    end

    test "config is empty" do
      arg = [total: "3"]
      config = []

      assert_raise Argx.Error, fn ->
        D.set_default(arg, config, __MODULE__)
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

  describe "get_default - function - arity is not zero" do
    test "in the current module - arity is not zero" do
      fun_expr = quote do: get_curr_ts(:second)
      D.get_default(fun_expr, __MODULE__)
    end

    test "in the another module - arity is not zero" do
      fun_expr = quote do: get_yesterday_ts(:second)
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
  end

  ###
  def get_curr_ts, do: @fixed_curr_ts
  def get_curr_ts(precision), do: precision
end
