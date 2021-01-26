defmodule ArgxTest do
  use ExUnit.Case

  import Argx

  describe "no defconfig" do
    defmodule Example1 do
      with_check configs(
                   name(:string, :a),
                   number(:string, :optional, :b),
                   cargoes(:list, :optional, :b, :c)
                 ) do
        def create(name, number, cargoes) when number |> is_bitstring() do
          {name, number, cargoes}
        end
      end
    end

    test "ok" do
      assert {"name", "number", [1]} == Example1.create("name", "number", [1])
      assert {"a", "b", []} == Example1.real_create__macro("a", "b", [])
    end
  end

  describe "defconfig" do
    defmodule Example2 do
      defconfig(AbcRule, account(:map, :optional))
      defconfig(XyzRule, [operation(:integer, :auto), reason(:string, :optional)])

      with_check configs(AbcRule, XyzRule) do
        def approve(reason) do
          {reason}
        end
      end
    end

    test "ok" do
      assert {"name"} == Example2.approve("name")
      assert {[]} == Example2.real_approve__macro([])
    end
  end

  describe "mix defconfig & with_check config" do
    defmodule Example3 do
      defconfig(AbcRule, account(:map, :optional))
      defconfig(XyzRule, [operation(:integer, :auto), reason(:string, :optional)])

      with_check configs(AbcRule, XyzRule, house(:string, :h)) do
        def get_one(one) do
          one
        end
      end
    end

    test "ok" do
      assert "name" == Example3.get_one("name")
      assert [] == Example3.real_get_one__macro([])
    end
  end
end
