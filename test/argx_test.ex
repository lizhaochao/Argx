defmodule Test.Helper.Defaulter do
  @moduledoc false

  def get_default, do: "default"
end

defmodule Project.Argx do
  @moduledoc false

  use Argx

  def format_errors(errors), do: errors
end

defmodule ArgxTest do
  @moduledoc false

  use ExUnit.Case

  import Project.Argx

  describe "with_check" do
    defmodule Project.Argx.A do
      @moduledoc false
      @fixed_curr_ts 1_618_653_110
      with_check configs(
                   one(:float, :auto),
                   two(:integer, :optional) || get_curr_ts(),
                   three(:string, :empty, 1..10),
                   four(:list) || [1, 2, 3],
                   five(:map, :empty),
                   six(:string, :optional, 7) || Test.Helper.Defaulter.get_default(),
                   seven(:boolean, :empty, :auto)
                 ) do
        def get(one, two, three, four, five, six, seven) do
          {one, two, three, four, five, six, seven}
        end
      end

      def get_curr_ts, do: @fixed_curr_ts
    end

    test "ok" do
      result1 = Project.Argx.A.get(1.1, 2, "ljy", [1, 2], %{a: 1}, "hellocc", "1")
      assert {1.1, 2, "ljy", [1, 2], %{a: 1}, "hellocc", true} == result1

      result2 = Project.Argx.A.get(1.1, nil, "ljy", nil, %{a: 1}, nil, true)
      expected_two = Project.Argx.A.get_curr_ts()
      expected_six = Test.Helper.Defaulter.get_default()
      assert {1.1, expected_two, "ljy", [1, 2, 3], %{a: 1}, expected_six, true} == result2
    end

    test "error" do
      result = Project.Argx.A.get(nil, "good", "", 1.23, %{}, "hello", nil)

      assert {
               :error,
               [
                 lacked: [:one, :three, :five, :seven],
                 error_type: [:two, :four],
                 out_of_range: [:six]
               ]
             } == result
    end
  end

  describe "defconfig" do
    defmodule Project.Argx.B do
      @moduledoc false

      defconfig(Rule, one(:string, :optional, 7) || Test.Helper.Defaulter.get_default())

      with_check configs(Rule) do
        def get(one) do
          {one}
        end
      end
    end

    test "ok" do
      assert {"hellocc"} == Project.Argx.B.get("hellocc")
      assert {"default"} == Project.Argx.B.get(nil)
    end

    test "error" do
      assert {:error, [error_type: [:one]]} == Project.Argx.B.get(:hello)
      assert {:error, [out_of_range: [:one]]} == Project.Argx.B.get("hello")
    end
  end

  describe "mixed defconfig & with_check" do
    defmodule Project.Argx.C do
      @moduledoc false

      defconfig(RuleA, one(:map, :optional))
      defconfig(RuleB, two(:integer, :auto) || 99)
      defconfig(RuleC, [three(:list, 2), four(:float, :auto, :empty)])

      with_check configs(RuleA, RuleB, RuleC, five(:string), six(:boolean, :auto)) do
        def get(one, two, three, four, five, six) when is_bitstring(five) do
          {one, two, three, four, five, six, :first}
        end

        def get(one, two, three, four, five, six) when is_integer(two) do
          {one, two, three, four, five, six, :second}
        end

        def get(one, two, three, four, five, six) do
          {one, two, three, four, five, six, :else}
        end
      end

      def format_errors(errors) do
        {:custom_err, errors}
      end
    end

    test "ok" do
      result1 = Project.Argx.C.get(%{}, 1, [1, 2], 1.23, "hello", true)
      assert {%{}, 1, [1, 2], 1.23, "hello", true, :first} == result1

      result2 = Project.Argx.C.get(%{}, nil, [1, 2], 1.23, "hello", 1)
      assert {%{}, 99, [1, 2], 1.23, "hello", true, :first} == result2
    end

    test "error" do
      result = Project.Argx.C.get(1, "a", [3], 0.0, 1.23, nil)

      assert {
               :custom_err,
               {
                 :error,
                 [
                   lacked: [:four, :six],
                   error_type: [:one, :two, :five],
                   out_of_range: [:three]
                 ]
               }
             } == result
    end
  end
end
