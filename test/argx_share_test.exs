defmodule ProjectB.Argx do
  use Argx.WithCheck, share: ProjectB.Argx.General
  def fmt_errors(errors), do: errors
end

defmodule ProjectB.Argx.General do
  use Argx.Defconfig

  defconfig(GeneralA, a(:boolean))
  defconfig(GeneralB, b(:integer))
  defconfig(GeneralC, [c(:float, 1..10), d(:boolean)])

  def fmt_errors(errors), do: {:general, errors}
end

defmodule ArgxShareTest do
  use ExUnit.Case

  import ProjectB.Argx

  describe "general configs" do
    test "__get_defconfigs__" do
      assert MapSet.new([:GeneralA, :GeneralB, :GeneralC]) ==
               Elixir.ProjectB.Argx.General.__get_defconfigs__()
               |> Map.keys()
               |> MapSet.new()
    end
  end

  describe "mixed defconfig & with_check" do
    defmodule ProjectB.Argx.A do
      @moduledoc false

      defconfig(RuleA, one(:map, :optional))

      with_check configs(
                   RuleA,
                   GeneralA,
                   two(:string),
                   GeneralC
                 ) do
        def get(one, two, a, c, d) when is_bitstring(one) do
          {one, two, a, c, d, :first}
        end

        def get(one, two, a, c, d) when is_nil(one) do
          {one, two, a, c, d, :i_am_nil}
        end

        def get(one, two, a, c, d) do
          {one, two, a, c, d, :else}
        end
      end

      def fmt_errors(errors) do
        {:custom_err, errors}
      end
    end

    test "get - ok" do
      result1 = ProjectB.Argx.A.get(%{}, "str", true, 9.9, true)
      assert {%{}, "str", true, 9.9, true, :else} == result1

      result2 = ProjectB.Argx.A.get(nil, "str", false, 9.9, true)
      assert {nil, "str", false, 9.9, true, :i_am_nil} == result2
    end

    test "get - error" do
      result = ProjectB.Argx.A.get(1, 1.23, nil, 99.9, "d")

      assert {
               :custom_err,
               {
                 :error,
                 [
                   error_type: [:d, :one, :two],
                   lacked: [:a],
                   out_of_range: [:c]
                 ]
               }
             } == result
    end
  end
end
