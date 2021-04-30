defmodule ConfigTest do
  @moduledoc false

  use ExUnit.Case

  import Argx.Config

  @warn true

  describe "get_configs_by_names/2" do
    test "max depth is 1" do
      # prepare
      max_depth = 1
      get = get_configs_by_names(@warn, max_depth)

      # 1 rule 1 field
      configs1 = %{RuleA: %{a: get_config(:string)}}
      assert [:a] == get.(configs1, [:RuleA]) |> Map.keys()

      # 1 rule 2 fields
      configs2 = %{RuleB: %{b: get_config(:string), c: get_config(:string)}}
      assert [:b, :c] == get.(configs2, [:RuleB]) |> Map.keys()

      # 2 rules 3 fields
      configs3 = Map.merge(configs1, configs2)
      assert [:a, :b, :c] == get.(configs3, [:RuleA, :RuleB]) |> Map.keys()
    end
  end

  ###
  def get_config(type, nested \\ nil) do
    %Argx.Config{
      type: type,
      auto: true,
      range: nil,
      default: nil,
      optional: false,
      empty: false,
      nested: nested
    }
  end
end
