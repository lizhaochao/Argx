defmodule ArgxErrorTest do
  use ExUnit.Case

  alias Argx.Const
  alias Argx.Error, as: E

  @check_types Const.check_types()

  @doc """
  result why not sorted?
  cause sorting is in sort_errors/1 function.
  """
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
      expected = [{:lacked, [:one]}, {:error_type, [:two]}]
      assert expected == E.merge_errors(left, right, @check_types)
      assert expected == E.merge_errors(right, left, @check_types)

      left = []
      right = [error_type: [:two], lacked: [:one], out_of_range: [:three]]
      expected = [{:out_of_range, [:three]}, {:lacked, [:one]}, {:error_type, [:two]}]
      assert expected == E.merge_errors(left, right, @check_types)
      assert expected == E.merge_errors(right, left, @check_types)

      left = []

      right = [
        error_type: [:a, :two],
        lacked: [:one],
        out_of_range: [:b, :three, :z]
      ]

      expected = [{:out_of_range, [:b, :three, :z]}, {:lacked, [:one]}, {:error_type, [:a, :two]}]

      assert expected == E.merge_errors(left, right, @check_types)
      assert expected == E.merge_errors(right, left, @check_types)
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

      assert [{:lacked, [:one]}, {:error_type, [:two]}] ==
               E.merge_errors(left, right, @check_types)

      left = [out_of_range: [:three]]
      right = [error_type: [:two], lacked: [:one]]

      assert [
               {:out_of_range, [:three]},
               {:lacked, [:one]},
               {:error_type, [:two]}
             ] ==
               E.merge_errors(left, right, @check_types)

      left = [error_type: [:a, :two]]

      right = [
        lacked: [:one],
        out_of_range: [:b, :three, :z]
      ]

      assert [
               {:out_of_range, [:b, :three, :z]},
               {:lacked, [:one]},
               {:error_type, [:a, :two]}
             ] ==
               E.merge_errors(left, right, @check_types)
    end

    test "merge" do
      #
      left = [lacked: [:h, :a]]
      right = [lacked: [:z, :m, :l]]
      assert [lacked: [:h, :a, :z, :m, :l]] == E.merge_errors(left, right, @check_types)

      #
      left = [lacked: [:h, :a]]
      right = [error_type: [:z, :m, :l], out_of_range: [:d, :c]]

      assert [
               out_of_range: [:d, :c],
               lacked: [:h, :a],
               error_type: [:z, :m, :l]
             ] ==
               E.merge_errors(left, right, @check_types)

      #
      left = [lacked: [:h, :a]]
      right = [lacked: [:z, :x], error_type: [:z, :m, :l], out_of_range: [:d, :c]]

      assert [
               out_of_range: [:d, :c],
               lacked: [:h, :a, :z, :x],
               error_type: [:z, :m, :l]
             ] ==
               E.merge_errors(left, right, @check_types)
    end

    @doc """
    result why not distinct?
    cause distinct is in sort_errors/1 function.
    """
    test "repeat key" do
      #
      left = [lacked: [:a, :b], out_of_range: [:m]]
      right = [out_of_range: [:m]]

      refute [
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
               {:out_of_range, [:m, :n, :c, :d]},
               {:lacked, [:a, :b]}
             ] ==
               E.merge_errors(left, right, @check_types)

      #
      left = [out_of_range: [:b, :a, :v], lacked: [:s, :q], error_type: [:i, :p]]
      right = [out_of_range: [:c, :d], lacked: [:k], error_type: [:y, :g]]

      assert [
               out_of_range: [:b, :a, :v, :c, :d],
               lacked: [:s, :q, :k],
               error_type: [:i, :p, :y, :g]
             ] ==
               E.merge_errors(left, right, @check_types)
    end
  end
end
