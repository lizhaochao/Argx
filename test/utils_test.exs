defmodule UtilsTest do
  use ExUnit.Case

  import Utils

  describe "m_to_kw" do
    test "only support map" do
      assert [] == %{} |> m_to_kw()

      assert_raise ArgumentError, fn ->
        [a: 1, b: 2] |> m_to_kw()
      end

      assert_raise ArgumentError, fn ->
        [] |> m_to_kw()
      end

      assert_raise ArgumentError, fn ->
        "config" |> m_to_kw()
      end
    end

    test "return keyword" do
      input = %{
        door: [
          %{location: [%{number: "1122333"}]}
        ]
      }

      expected = [
        door: [
          [location: [[number: "1122333"]]]
        ]
      ]

      assert expected == input |> m_to_kw()
    end
  end
end
