defmodule Test.Helper.Defaulter do
  @moduledoc false

  def get_default, do: "default"
end

defmodule TestArgx do
  @moduledoc false

  use Argx

  def format_errors(errors), do: errors
end

defmodule ArgxTest do
  @moduledoc false

  use ExUnit.Case

  import TestArgx

  describe "with_check" do
    defmodule TestArgx.A do
      @moduledoc false
      @fixed_curr_ts 1_618_653_110
      with_check configs(
                   one(:float, :auto),
                   two(:integer, :optional) || get_curr_ts(),
                   three(:string, 1..10),
                   four(:list) || [1, 2, 3],
                   five(:map),
                   six(:string, :optional, 7) || Test.Helper.Defaulter.get_default()
                 ) do
        def get(one, two, three, four, five, six) do
          {one, two, three, four, five, six}
        end
      end

      def get_curr_ts, do: @fixed_curr_ts
    end

    test "ok" do
      result1 = TestArgx.A.get(1.1, 2, "ljy", [1, 2], %{a: 1}, "hellocc")
      assert {1.1, 2, "ljy", [1, 2], %{a: 1}, "hellocc"} == result1

      result2 = TestArgx.A.get(1.1, nil, "ljy", nil, %{a: 1}, nil)
      expected_two = TestArgx.A.get_curr_ts()
      expected_six = Test.Helper.Defaulter.get_default()
      assert {1.1, expected_two, "ljy", [1, 2, 3], %{a: 1}, expected_six} == result2
    end

    test "error" do
      result = TestArgx.A.get(nil, "good", "", 1.23, [], "hello")

      assert {
               :error,
               [
                 lacked: [:one],
                 error_type: [:two, :four, :five],
                 out_of_range: [:three, :six]
               ]
             } == result
    end
  end

  describe "defconfig" do
    defmodule TestArgx.B do
      @moduledoc false

      defconfig(Rule, one(:string, :optional, 7) || Test.Helper.Defaulter.get_default())

      with_check configs(Rule) do
        def get(one) do
          {one}
        end
      end
    end

    test "ok" do
      assert {"hellocc"} == TestArgx.B.get("hellocc")
      assert {"default"} == TestArgx.B.get(nil)
    end

    test "error" do
      assert {:error, [error_type: [:one]]} == TestArgx.B.get(:hello)
      assert {:error, [out_of_range: [:one]]} == TestArgx.B.get("hello")
    end
  end

  describe "mixed defconfig & with_check" do
    defmodule TestArgx.C do
      @moduledoc false

      defconfig(RuleA, one(:map, :optional))
      defconfig(RuleB, two(:integer, :auto) || 99)
      defconfig(RuleC, [three(:list, 2), four(:float, :auto)])

      with_check configs(RuleA, RuleB, RuleC, five(:string)) do
        def get(one, two, three, four, five) do
          {one, two, three, four, five}
        end
      end

      def format_errors(errors) do
        {:custom_err, errors}
      end
    end

    test "ok" do
      assert {%{}, 1, [1, 2], 1.23, "hello"} == TestArgx.C.get(%{}, 1, [1, 2], 1.23, "hello")
      assert {%{}, 99, [1, 2], 1.23, "hello"} == TestArgx.C.get(%{}, nil, [1, 2], 1.23, "hello")
    end

    test "error" do
      result = TestArgx.C.get(1, "a", [3], nil, 1.23)

      assert {
               :custom_err,
               {
                 :error,
                 [
                   lacked: [:four],
                   error_type: [:one, :two, :five],
                   out_of_range: [:three]
                 ]
               }
             } == result
    end
  end
end
