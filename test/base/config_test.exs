defmodule ArgxConfigTest do
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

    test "max depth is 2" do
      # prepare
      max_depth = 2
      get = get_configs_by_names(@warn, max_depth)

      #
      configs1 = %{
        RuleA: %{a: get_config(:string, :RuleB)},
        RuleB: %{b: get_config(:string)}
      }

      # 1 rule
      result = get.(configs1, [:RuleA])
      assert [:a] == Map.keys(result)
      assert result |> Map.get(:a) |> Map.get(:nested) |> Map.get(:b) |> is_struct()

      #
      configs2 = %{
        RuleA: %{a: get_config(:string, :RuleB)},
        RuleB: %{b: get_config(:string)},
        RuleC: %{c: get_config(:string, :RuleD)},
        RuleD: %{d: get_config(:string)}
      }

      # 2 rules
      result = get.(configs2, [:RuleA, :RuleC])
      assert [:a, :c] == Map.keys(result)
      assert result |> Map.get(:a) |> Map.get(:nested) |> Map.get(:b) |> is_struct()
      assert result |> Map.get(:c) |> Map.get(:nested) |> Map.get(:d) |> is_struct()
    end

    test "max depth is 3" do
      # prepare
      max_depth = 3
      get = get_configs_by_names(@warn, max_depth)

      #
      configs = %{
        RuleA: %{a: get_config(:string, :RuleB)},
        RuleB: %{b: get_config(:string, :RuleC)},
        RuleC: %{c: get_config(:string)}
      }

      # 1 rule
      result = get.(configs, [:RuleA])
      assert [:a] == Map.keys(result)

      assert result
             |> Map.get(:a)
             |> Map.get(:nested)
             |> Map.get(:b)
             |> Map.get(:nested)
             |> Map.get(:c)
             |> is_struct()

      # 2 rules
      result = get.(configs, [:RuleA, :RuleB])
      assert [:a, :b] == Map.keys(result)
      assert result |> Map.get(:b) |> Map.get(:nested) |> Map.get(:c) |> is_struct()
    end

    test "max depth is 4" do
      # prepare
      max_depth = 4
      get = get_configs_by_names(@warn, max_depth)

      #
      configs = %{
        RuleA: %{a: get_config(:string, :RuleB)},
        RuleB: %{b: get_config(:string, :RuleC)},
        RuleC: %{c: get_config(:string, :RuleD)},
        RuleD: %{d: get_config(:string)}
      }

      # 1 rule
      result = get.(configs, [:RuleA])
      assert [:a] == Map.keys(result)

      assert result
             |> Map.get(:a)
             |> Map.get(:nested)
             |> Map.get(:b)
             |> Map.get(:nested)
             |> Map.get(:c)
             |> Map.get(:nested)
             |> Map.get(:d)
             |> is_struct()

      # 4 rules
      result = get.(configs, [:RuleA, :RuleB, :RuleC, :RuleD])
      assert [:a, :b, :c, :d] == Map.keys(result)

      assert result
             |> Map.get(:b)
             |> Map.get(:nested)
             |> Map.get(:c)
             |> Map.get(:nested)
             |> Map.get(:d)
             |> is_struct()

      assert result
             |> Map.get(:c)
             |> Map.get(:nested)
             |> Map.get(:d)
             |> is_struct()
    end

    test "repeat rule names" do
      # prepare
      max_depth = 1
      configs = %{RuleA: %{a: get_config(:string)}}

      get = get_configs_by_names(@warn, max_depth)
      result = get.(configs, [:RuleA, :RuleA])
      assert [:a] == Map.keys(result)
      assert result |> Map.get(:a) |> is_struct()
    end
  end

  ###
  def get_config(type, nested_name \\ nil) do
    %Argx.Config{
      type: type,
      auto: true,
      range: nil,
      default: nil,
      optional: false,
      empty: false,
      nested: nested_name
    }
  end
end
