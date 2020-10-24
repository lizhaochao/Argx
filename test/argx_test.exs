defmodule ArgxTest do
  use ExUnit.Case
  doctest Argx

  import Argx

  describe "validate" do
    test "empty config & args" do
      assert false == %{} |> validate(%{})
    end

    test "validate - 2 nested array" do
      config = %{
        warehouse: %{
          update: %{
            result: %{},
            door: %{
              required: true,
              type: :array,
              item: %{
                location: %{
                  required: true,
                  type: :array,
                  item: %{
                    number: %{
                      required: true,
                      type: :string,
                      length: 12
                    }
                  }
                }
              }
            }
          }
        }
      }

      input = %{
        door: [
          %{
            location: [
              %{number: "DOOR202010011"},
              %{number: "DOOR202010012"}
            ]
          },
          %{
            location: [
              %{number: "DOOR202010021"},
              %{number: "DOOR202010022"}
            ]
          }
        ]
      }

      assert true == input |> validate(config.warehouse.update)
    end
  end
end
