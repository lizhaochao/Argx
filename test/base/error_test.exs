defmodule ArgxErrorTest do
  use ExUnit.Case

  alias Argx.Const
  alias Argx.Error, as: E

  @check_types Const.check_types()

  describe "merge_errors/3" do
    test "both left & right are empty" do
      {left, right} = {[], []}
      assert [] == E.merge_errors(left, right, @check_types)
    end

    test "left/right is empty" do
      left = []
      right = [lacked: [:one]]
      assert right == E.merge_errors(left, right, @check_types)
      assert right == E.merge_errors(right, left, @check_types)

      left = []
      right = [error_type: [:two], lacked: [:one]]
      assert right == E.merge_errors(left, right, @check_types)
      assert right == E.merge_errors(right, left, @check_types)

      left = []
      right = [error_type: [:two], lacked: [:one], out_of_range: [:three]]
      assert right == E.merge_errors(left, right, @check_types)
      assert right == E.merge_errors(right, left, @check_types)

      left = []

      right = [
        error_type: [:a, :two],
        lacked: [:one],
        out_of_range: [:b, :three, :z]
      ]

      assert right == E.merge_errors(left, right, @check_types)
      assert right == E.merge_errors(right, left, @check_types)
    end

    test "left/right is []" do
      left = [lacked: []]
      right = [lacked: [:a]]
      assert [lacked: [:a]] == E.merge_errors(left, right, @check_types)
      assert [lacked: [:a]] == E.merge_errors(right, left, @check_types)

      left = [lacked: [], error_type: [], out_of_range: []]
      right = [lacked: [:a]]
      assert [lacked: [:a]] == E.merge_errors(left, right, @check_types)
      assert [lacked: [:a]] == E.merge_errors(right, left, @check_types)
    end

    test "both left & right are not empty" do
      left = [lacked: [:one]]
      right = [lacked: [:two]]
      assert [lacked: [:one, :two]] == E.merge_errors(left, right, @check_types)

      left = [lacked: [:one]]
      right = [error_type: [:two]]
      assert [error_type: [:two], lacked: [:one]] == E.merge_errors(left, right, @check_types)

      left = [out_of_range: [:three]]
      right = [error_type: [:two], lacked: [:one]]

      assert [error_type: [:two], lacked: [:one], out_of_range: [:three]] ==
               E.merge_errors(left, right, @check_types)

      left = [error_type: [:a, :two]]

      right = [
        lacked: [:one],
        out_of_range: [:b, :three, :z]
      ]

      assert [error_type: [:a, :two], lacked: [:one], out_of_range: [:b, :three, :z]] ==
               E.merge_errors(left, right, @check_types)
    end

    test "merge & sort" do
      #
      left = [lacked: [:h, :a]]
      right = [lacked: [:z, :m, :l]]
      assert [lacked: [:a, :h, :l, :m, :z]] == E.merge_errors(left, right, @check_types)

      #
      left = [lacked: [:h, :a]]
      right = [error_type: [:z, :m, :l], out_of_range: [:d, :c]]

      assert [
               error_type: [:l, :m, :z],
               lacked: [:a, :h],
               out_of_range: [:c, :d]
             ] ==
               E.merge_errors(left, right, @check_types)

      #
      left = [lacked: [:h, :a]]
      right = [lacked: [:z, :x], error_type: [:z, :m, :l], out_of_range: [:d, :c]]

      assert [
               error_type: [:l, :m, :z],
               lacked: [:a, :h, :x, :z],
               out_of_range: [:c, :d]
             ] ==
               E.merge_errors(left, right, @check_types)
    end

    test "repeat key" do
      #
      left = [lacked: [:a, :b], out_of_range: [:m]]
      right = [out_of_range: [:m]]

      assert [
               lacked: [:a, :b],
               out_of_range: [:m]
             ] ==
               E.merge_errors(left, right, @check_types)
    end

    test "any" do
      #
      left = [lacked: [:a, :b], out_of_range: [:m, :n]]
      right = [out_of_range: [:c, :d]]

      assert [
               lacked: [:a, :b],
               out_of_range: [:c, :d, :m, :n]
             ] ==
               E.merge_errors(left, right, @check_types)

      #
      left = [out_of_range: [:b, :a, :v], lacked: [:s, :q], error_type: [:i, :p]]
      right = [out_of_range: [:c, :d], lacked: [:k], error_type: [:y, :g]]

      assert [
               error_type: [:g, :i, :p, :y],
               lacked: [:k, :q, :s],
               out_of_range: [:a, :b, :c, :d, :v]
             ] ==
               E.merge_errors(left, right, @check_types)
    end
  end
end
