defmodule MatcherTest do
  @moduledoc false

  use ExUnit.Case

  alias Argx.Matcher, as: M

  test "match error" do
    errors = []
    args = [one: "", two: [1, 2, 3], three: 9]

    configs = [
      one: %Argx.Config{
        type: :string,
        optional: false,
        empty: true,
        range: nil,
        # following configs dont care
        auto: false,
        default: "hi"
      },
      two: %Argx.Config{
        type: :boolean,
        optional: false,
        empty: false,
        range: nil,
        # following configs dont care
        auto: false,
        default: "hi"
      },
      three: %Argx.Config{
        type: :integer,
        optional: false,
        empty: false,
        range: 10,
        # following configs dont care
        auto: false,
        default: "hi"
      }
    ]

    assert {
             {:error, [out_of_range: [:three], error_type: [:two], lacked: [:one]]},
             args
           } ==
             {errors, args, configs}
             |> M.lacked()
             |> M.drop_checked_keys(args, configs)
             |> M.error_type()
             |> M.drop_checked_keys(args, configs)
             |> M.out_of_range()
             |> M.output_result(args)
  end

  describe "lacked" do
    test "case 1 - ok" do
      errors = []
      args = [one: :hello]

      [{true, true}, {true, false}, {false, true}, {false, false}]
      |> Enum.each(fn {empty, optional} ->
        configs = [
          one: %Argx.Config{
            empty: empty,
            optional: optional,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            type: :string
          }
        ]

        assert [] == M.lacked({errors, args, configs})
      end)
    end

    test "case 2 - ok" do
      errors = []
      args = [one: ""]

      [{false, true}, {false, false}]
      |> Enum.each(fn {empty, optional} ->
        configs = [
          one: %Argx.Config{
            empty: empty,
            optional: optional,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            type: :string
          }
        ]

        assert [] == M.lacked({errors, args, configs})
      end)
    end

    test "case 3 - ok" do
      errors = []
      args = [one: nil]

      [{true, true}, {false, true}]
      |> Enum.each(fn {empty, optional} ->
        configs = [
          one: %Argx.Config{
            empty: empty,
            optional: optional,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            type: :string
          }
        ]

        assert [] == M.lacked({errors, args, configs})
      end)
    end

    test "case 1 - error" do
      errors = []
      args = [one: ""]

      [{true, false}]
      |> Enum.each(fn {empty, optional} ->
        configs = [
          one: %Argx.Config{
            empty: empty,
            optional: optional,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            type: :string
          }
        ]

        assert {:error, [lacked: [:one]]} == M.lacked({errors, args, configs})
      end)
    end

    test "case 2 - error" do
      errors = []
      args = [one: nil]

      [{true, false}, {false, false}]
      |> Enum.each(fn {empty, optional} ->
        configs = [
          one: %Argx.Config{
            empty: empty,
            optional: optional,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            type: :string
          }
        ]

        assert {:error, [lacked: [:one]]} == M.lacked({errors, args, configs})
      end)
    end
  end

  describe "error type" do
    test "case 1 - ok" do
      errors = []
      args = [one: "hello"]

      [{:string, true}, {:string, false}]
      |> Enum.each(fn {type, optional} ->
        configs = [
          one: %Argx.Config{
            type: type,
            optional: optional,
            empty: false,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7
          }
        ]

        assert [] == M.error_type({errors, args, configs})
      end)
    end

    test "case 2 - ok" do
      errors = []
      args = [one: ""]

      [{:string, true}, {:string, false}]
      |> Enum.each(fn {type, optional} ->
        configs = [
          one: %Argx.Config{
            type: type,
            optional: optional,
            empty: false,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7
          }
        ]

        assert [] == M.error_type({errors, args, configs})
      end)
    end

    test "case 3 - ok" do
      errors = []
      args = [one: nil]

      [{:string, true}, {:integer, true}]
      |> Enum.each(fn {type, optional} ->
        configs = [
          one: %Argx.Config{
            type: type,
            optional: optional,
            empty: false,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7
          }
        ]

        assert [] == M.error_type({errors, args, configs})
      end)
    end

    test "case 1 - error" do
      errors = []
      args = [one: "hello"]

      [{:integer, true}, {:boolean, false}]
      |> Enum.each(fn {type, optional} ->
        configs = [
          one: %Argx.Config{
            type: type,
            optional: optional,
            empty: false,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7
          }
        ]

        assert {:error, [error_type: [:one]]} == M.error_type({errors, args, configs})
      end)
    end

    test "case 2 - error" do
      errors = []
      args = [one: ""]

      [{:integer, true}, {:boolean, false}]
      |> Enum.each(fn {type, optional} ->
        configs = [
          one: %Argx.Config{
            type: type,
            optional: optional,
            empty: false,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7
          }
        ]

        assert {:error, [error_type: [:one]]} == M.error_type({errors, args, configs})
      end)
    end
  end

  describe "out of range" do
    test "case 1 - ok" do
      errors = []
      args = [one: "hello"]

      [{5, true}, {5, false}, {nil, true}, {nil, false}]
      |> Enum.each(fn {range, optional} ->
        configs = [
          one: %Argx.Config{
            range: range,
            optional: optional,
            # following configs dont care
            type: :string,
            empty: false,
            auto: false,
            default: "hi"
          }
        ]

        assert [] == M.out_of_range({errors, args, configs})
      end)
    end

    test "case 2 - ok" do
      errors = []
      args = [one: ""]

      [{0, true}, {0, false}, {nil, true}, {nil, false}]
      |> Enum.each(fn {range, optional} ->
        configs = [
          one: %Argx.Config{
            range: range,
            optional: optional,
            # following configs dont care
            type: :string,
            empty: false,
            auto: false,
            default: "hi"
          }
        ]

        assert [] == M.out_of_range({errors, args, configs})
      end)
    end

    test "case 3 - ok" do
      errors = []
      args = [one: nil]

      [{5, true}, {nil, true}]
      |> Enum.each(fn {range, optional} ->
        configs = [
          one: %Argx.Config{
            range: range,
            optional: optional,
            # following configs dont care
            type: :string,
            empty: false,
            auto: false,
            default: "hi"
          }
        ]

        assert [] == M.out_of_range({errors, args, configs})
      end)
    end

    test "case 1 - error" do
      errors = []
      args = [one: "hello"]

      [{1, true}, {1, false}]
      |> Enum.each(fn {range, optional} ->
        configs = [
          one: %Argx.Config{
            range: range,
            optional: optional,
            # following configs dont care
            type: :string,
            empty: false,
            auto: false,
            default: "hi"
          }
        ]

        assert {:error, [out_of_range: [:one]]} == M.out_of_range({errors, args, configs})
      end)
    end

    test "case 2 - error" do
      errors = []
      args = [one: ""]

      [{5, true}, {5, false}]
      |> Enum.each(fn {range, optional} ->
        configs = [
          one: %Argx.Config{
            range: range,
            optional: optional,
            # following configs dont care
            type: :string,
            empty: false,
            auto: false,
            default: "hi"
          }
        ]

        assert {:error, [out_of_range: [:one]]} == M.out_of_range({errors, args, configs})
      end)
    end
  end
end
