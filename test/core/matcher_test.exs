defmodule MatcherTest do
  @moduledoc false

  use ExUnit.Case

  alias Argx.Matcher

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
end
