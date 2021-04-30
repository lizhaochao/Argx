defmodule MatcherTest do
  @moduledoc false

  use ExUnit.Case

  alias Argx.{Checker, Matcher}
  alias Argx.Matcher.Helper, as: M

  @default_path []
  @curr_m __MODULE__

  test "match error" do
    args = [one: "", two: [1, 2, 3], three: 9]

    configs = [
      one: %Argx.Config{
        type: :string,
        optional: false,
        empty: true,
        range: nil,
        # following configs dont care
        auto: false,
        default: "hi",
        nested: nil
      },
      two: %Argx.Config{
        type: :boolean,
        optional: false,
        empty: false,
        range: nil,
        # following configs dont care
        auto: false,
        default: "hi",
        nested: nil
      },
      three: %Argx.Config{
        type: :integer,
        optional: false,
        empty: false,
        range: 10,
        # following configs dont care
        auto: false,
        default: "hi",
        nested: nil
      }
    ]

    expected_errors = [out_of_range: [:three], error_type: [:two], lacked: [:one]]
    from = :argx
    match = Matcher.match(from)
    {errors, _} = match.(args, configs, @curr_m)
    assert expected_errors == errors
  end

  describe "lacked" do
    test "case 1 - ok" do
      errors = []
      arg = {:one, :hello}

      [{true, true}, {true, false}, {false, true}, {false, false}]
      |> Enum.each(fn {empty, optional} ->
        configs = {
          :one,
          %Argx.Config{
            empty: empty,
            optional: optional,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            type: :string,
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.lacked(arg, configs, @default_path, errors, &M.join_path/2)

        assert [] == errors
      end)
    end

    test "case 2 - ok" do
      errors = []
      arg = {:one, ""}

      [{false, true}, {false, false}]
      |> Enum.each(fn {empty, optional} ->
        configs = {
          :one,
          %Argx.Config{
            empty: empty,
            optional: optional,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            type: :string,
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.lacked(arg, configs, @default_path, errors, &M.join_path/2)

        assert [] == errors
      end)
    end

    test "case 3 - ok" do
      errors = []
      arg = {:one, nil}

      [{true, true}, {false, true}]
      |> Enum.each(fn {empty, optional} ->
        configs = {
          :one,
          %Argx.Config{
            empty: empty,
            optional: optional,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            type: :string,
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.lacked(arg, configs, @default_path, errors, &M.join_path/2)

        assert [] == errors
      end)
    end

    test "case 1 - error" do
      errors = []
      arg = {:one, ""}

      [{true, false}]
      |> Enum.each(fn {empty, optional} ->
        configs = {
          :one,
          %Argx.Config{
            empty: empty,
            optional: optional,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            type: :string,
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.lacked(arg, configs, @default_path, errors, &M.join_path/2)

        assert [lacked: [:one]] == errors
      end)
    end

    test "case 2 - error" do
      errors = []
      arg = {:one, nil}

      [{true, false}, {false, false}]
      |> Enum.each(fn {empty, optional} ->
        configs = {
          :one,
          %Argx.Config{
            empty: empty,
            optional: optional,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            type: :string,
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.lacked(arg, configs, @default_path, errors, &M.join_path/2)

        assert [lacked: [:one]] == errors
      end)
    end
  end

  describe "error type" do
    test "case 1 - ok" do
      errors = []
      arg = {:one, "hello"}

      [{:string, true}, {:string, false}]
      |> Enum.each(fn {type, optional} ->
        configs = {
          :one,
          %Argx.Config{
            type: type,
            optional: optional,
            empty: false,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.error_type({errors, arg, configs}, @default_path, &M.join_path/2)

        assert [] == errors
      end)
    end

    test "case 2 - ok" do
      errors = []
      arg = {:one, ""}

      [{:string, true}, {:string, false}]
      |> Enum.each(fn {type, optional} ->
        configs = {
          :one,
          %Argx.Config{
            type: type,
            optional: optional,
            empty: false,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.error_type({errors, arg, configs}, @default_path, &M.join_path/2)

        assert [] == errors
      end)
    end

    test "case 3 - ok" do
      errors = []
      arg = {:one, nil}

      [{:string, true}, {:integer, true}]
      |> Enum.each(fn {type, optional} ->
        configs = {
          :one,
          %Argx.Config{
            type: type,
            optional: optional,
            empty: false,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.error_type({errors, arg, configs}, @default_path, &M.join_path/2)

        assert [] == errors
      end)
    end

    test "case 1 - error" do
      errors = []
      arg = {:one, "hello"}

      [{:integer, true}, {:boolean, false}]
      |> Enum.each(fn {type, optional} ->
        configs = {
          :one,
          %Argx.Config{
            type: type,
            optional: optional,
            empty: false,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.error_type({errors, arg, configs}, @default_path, &M.join_path/2)

        assert [error_type: [:one]] == errors
      end)
    end

    test "case 2 - error" do
      errors = []
      arg = {:one, ""}

      [{:integer, true}, {:boolean, false}]
      |> Enum.each(fn {type, optional} ->
        configs = {
          :one,
          %Argx.Config{
            type: type,
            optional: optional,
            empty: false,
            # following configs dont care
            auto: false,
            default: "hi",
            range: 7,
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.error_type({errors, arg, configs}, @default_path, &M.join_path/2)

        assert [error_type: [:one]] == errors
      end)
    end
  end

  describe "out of range" do
    test "case 1 - ok" do
      errors = []
      arg = {:one, "hello"}

      [{5, true}, {5, false}, {nil, true}, {nil, false}]
      |> Enum.each(fn {range, optional} ->
        configs = {
          :one,
          %Argx.Config{
            range: range,
            optional: optional,
            # following configs dont care
            type: :string,
            empty: false,
            auto: false,
            default: "hi",
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.error_type({errors, arg, configs}, @default_path, &M.join_path/2)

        assert [] == errors
      end)
    end

    test "case 2 - ok" do
      errors = []
      arg = {:one, ""}

      [{0, true}, {0, false}, {nil, true}, {nil, false}]
      |> Enum.each(fn {range, optional} ->
        configs = {
          :one,
          %Argx.Config{
            range: range,
            optional: optional,
            # following configs dont care
            type: :string,
            empty: false,
            auto: false,
            default: "hi",
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.error_type({errors, arg, configs}, @default_path, &M.join_path/2)

        assert [] == errors
      end)
    end

    test "case 3 - ok" do
      errors = []
      arg = {:one, nil}

      [{5, true}, {nil, true}]
      |> Enum.each(fn {range, optional} ->
        configs = {
          :one,
          %Argx.Config{
            range: range,
            optional: optional,
            # following configs dont care
            type: :string,
            empty: false,
            auto: false,
            default: "hi",
            nested: nil
          }
        }

        {errors, _arg, _config} =
          Checker.error_type({errors, arg, configs}, @default_path, &M.join_path/2)

        assert [] == errors
      end)
    end

    test "case 1 - error" do
      errors = []
      arg = {:one, "hello"}

      [{1, true}, {1, false}]
      |> Enum.each(fn {range, optional} ->
        configs = {
          :one,
          %Argx.Config{
            range: range,
            optional: optional,
            # following configs dont care
            type: :string,
            empty: false,
            auto: false,
            default: "hi",
            nested: nil
          }
        }

        assert [out_of_range: [:one]] ==
                 Checker.out_of_range({errors, arg, configs}, @default_path, &M.join_path/2)
      end)
    end

    test "case 2 - error" do
      errors = []
      arg = {:one, ""}

      [{5, true}, {5, false}]
      |> Enum.each(fn {range, optional} ->
        configs = {
          :one,
          %Argx.Config{
            range: range,
            optional: optional,
            # following configs dont care
            type: :string,
            empty: false,
            auto: false,
            default: "hi",
            nested: nil
          }
        }

        assert [out_of_range: [:one]] ==
                 Checker.out_of_range({errors, arg, configs}, @default_path, &M.join_path/2)
      end)
    end
  end
end
