ProjectA.Helper |> defmodule(do: def(get_default, do: "default"))

defmodule ProjectA.Argx do
  use Argx.WithCheck, warn: false
  def fmt_errors(errors), do: errors
end

defmodule ArgxWithCheckTest do
  use ExUnit.Case

  import ProjectA.Argx

  describe "with_check" do
    defmodule ProjectA.Argx.A do
      @fixed_curr_ts 1_618_653_110
      with_check configs(
                   one(:float, :auto),
                   two(:integer, :optional) || get_curr_ts(),
                   three(:string, :empty, 1..10),
                   four(:list) || [1, 2, 3],
                   five(:map, :empty),
                   six(:string, :optional, 7) || ProjectA.Helper.get_default(),
                   seven(:boolean, :empty, :auto)
                 ) do
        def get(one, two, three, four, five, six, seven) do
          {one, two, three, four, five, six, seven}
        end
      end

      def get_curr_ts, do: @fixed_curr_ts
    end

    test "ok" do
      result1 = ProjectA.Argx.A.get(1.1, 2, "ljy", [1, 2], %{a: 1}, "hellocc", "1")
      assert {1.1, 2, "ljy", [1, 2], %{a: 1}, "hellocc", true} == result1

      result2 = ProjectA.Argx.A.get(1.1, nil, "ljy", nil, %{a: 1}, nil, true)
      expected_two = ProjectA.Argx.A.get_curr_ts()
      expected_six = Elixir.ProjectA.Helper.get_default()
      assert {1.1, expected_two, "ljy", [1, 2, 3], %{a: 1}, expected_six, true} == result2
    end

    test "error" do
      result = ProjectA.Argx.A.get(nil, "good", "", 1.23, %{}, "hello", nil)

      assert {
               :error,
               [
                 error_type: [:four, :two],
                 lacked: [:five, :one, :seven, :three],
                 out_of_range: [:six]
               ]
             } == result
    end

    test "get configs" do
      configs = ProjectA.Argx.A.__get_get_configs__()
      arg_names = Keyword.keys(configs)
      assert [:one, :two, :three, :four, :five, :six, :seven] == arg_names
    end
  end

  describe "defconfig" do
    defmodule ProjectA.Argx.B do
      defconfig("rule", one(:string, :optional, 7) || ProjectA.Helper.get_default())

      with_check configs("rule") do
        def get(one) do
          %{
            a: [
              %{b: "b1"},
              %{b: "b2"}
            ],
            b: [1, 2, 3]
          }

          {one}
        end
      end
    end

    test "ok" do
      assert {"hellocc"} == ProjectA.Argx.B.get("hellocc")
      assert {"default"} == ProjectA.Argx.B.get(nil)
    end

    test "error" do
      assert {:error, [error_type: [:one]]} == ProjectA.Argx.B.get(:hello)
      assert {:error, [out_of_range: [:one]]} == ProjectA.Argx.B.get("hello")
    end
  end

  describe "mixed defconfig & with_check" do
    defmodule ProjectA.Argx.C do
      defconfig(RuleA, one(:map, :optional, :checkbox))
      defconfig(RuleB, two(:integer, :auto) || 99)
      defconfig(RuleC, [three(:list, 2), four(:float, :auto, :empty, :checkbox)])
      defconfig(SimpleMapRule, [a(:string)])

      with_check configs(
                   RuleA,
                   RuleB,
                   five(:string),
                   RuleC,
                   six({:list, SimpleMapRule})
                 ) do
        def get(one, two, three, four, five, six) when is_bitstring(one) do
          {one, two, three, four, five, six, :first}
        end

        def get(one, two, three, four, five, six) when is_nil(one) do
          {one, two, three, four, five, six, :i_am_nil}
        end

        def get(one, two, three, four, five, six) do
          {one, two, three, four, five, six, :else}
        end
      end

      with_check configs(RuleA) do
        def post(one) when %{a: "one"} == one do
          {:error, :second}
        end

        def post(one) when is_map(one) do
          {one, :first}
        end

        def post(one) do
          {one, :else}
        end
      end

      def fmt_errors(errors) do
        {:custom_err, errors}
      end
    end

    test "get - ok" do
      result1 = ProjectA.Argx.C.get(%{}, 1, [1, 2], 1.23, "hello", [%{a: "a"}])
      assert {%{}, 1, [1, 2], 1.23, "hello", [%{a: "a"}], :else} == result1

      result2 = ProjectA.Argx.C.get(nil, nil, [1, 2], 1.23, "hello", [%{a: "a"}])
      assert {nil, 99, [1, 2], 1.23, "hello", [%{a: "a"}], :i_am_nil} == result2
    end

    test "get - error" do
      result = ProjectA.Argx.C.get(nil, "a", [3], 0.0, 1.23, nil)

      assert {:custom_err,
              {:error,
               [
                 checkbox_error: [:four, :one],
                 error_type: [:five, :two],
                 lacked: [:six],
                 out_of_range: [:three]
               ]}} == result
    end

    test "post - ok" do
      assert {%{}, :first} == ProjectA.Argx.C.post(%{})
    end

    test "post - error" do
      assert {:error, :second} == ProjectA.Argx.C.post(%{a: "one"})
    end

    test "post - checkbox error" do
      assert {:custom_err, {:error, [checkbox_error: [:one]]}} == ProjectA.Argx.C.post(nil)
    end
  end

  describe "checkbox" do
    defmodule ProjectA.Argx.D do
      with_check configs(
                   one(:string, :checkbox),
                   two(:string, :optional, :checkbox),
                   three(:string)
                 ) do
        def get(one, two, three) do
          {one, two, three}
        end
      end

      with_check configs(
                   one(:string, :checkbox, :empty),
                   two(:string)
                 ) do
        def post(one, two) do
          {one, two}
        end
      end
    end

    ###
    test "ok - two args set :checkbox" do
      result = ProjectA.Argx.D.get(nil, "two", "three")
      assert {nil, "two", "three"} == result

      result = ProjectA.Argx.D.get("one", nil, "three")
      assert {"one", nil, "three"} == result

      result = ProjectA.Argx.D.get("one", "two", "three")
      assert {"one", "two", "three"} == result
    end

    test "error - two args set :checkbox" do
      assert {:error, [checkbox_error: [:one, :two]]} == ProjectA.Argx.D.get(nil, nil, "three")
    end

    ###
    test "ok - only one arg set :checkbox" do
      result = ProjectA.Argx.D.post("one", "two")
      assert {"one", "two"} == result
    end

    test "error - only one arg set :checkbox" do
      assert {:error, [checkbox_error: [:one]]} == ProjectA.Argx.D.post(nil, "two")
      assert {:error, [checkbox_error: [:one]]} == ProjectA.Argx.D.post("", "two")
    end
  end

  describe "radio" do
    defmodule ProjectA.Argx.E do
      with_check configs(
                   one(:string, :radio),
                   two(:string, :optional, :radio),
                   three(:string)
                 ) do
        def get(one, two, three) do
          {one, two, three}
        end
      end

      with_check configs(
                   one(:string, :radio, :empty),
                   two(:string)
                 ) do
        def post(one, two) do
          {one, two}
        end
      end
    end

    ###
    test "ok - two args set :radio" do
      result = ProjectA.Argx.E.get(nil, "two", "three")
      assert {nil, "two", "three"} == result

      result = ProjectA.Argx.E.get("one", nil, "three")
      assert {"one", nil, "three"} == result
    end

    test "error - two args set :radio" do
      assert {:error, [radio_error: [:one, :two]]} == ProjectA.Argx.E.get(nil, nil, "three")
    end

    ###
    test "ok - only one arg set :radio" do
      result = ProjectA.Argx.E.post("one", "two")
      assert {"one", "two"} == result
    end

    test "error - only one arg set :radio" do
      assert {:error, [radio_error: [:one]]} == ProjectA.Argx.E.post(nil, "one")
      assert {:error, [radio_error: [:one]]} == ProjectA.Argx.E.post("", "one")
    end
  end
end
