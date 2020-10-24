defmodule ParserTest do
  use ExUnit.Case

  import Parser

  describe "parse result by simple mode" do
    test "2 nested array - true" do
      result = %{
        door: %{
          item: %{
            location: %{
              item: %{number: %{length: 12, required: true, type: :string}},
              required: true,
              type: :array
            }
          },
          required: true,
          type: :array
        },
        result: %{
          [:door, :item, :location, :item, :number] => [true],
          [:door, :item, :location] => [true],
          [:door] => [true]
        }
      }

      assert true == result |> parse_result(:simple)
    end
  end
end
