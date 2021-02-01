defmodule Argx.A.B.C.Helper do
  @moduledoc false

  def get_default_cargoes do
    [:default_cargoes_from_fun]
  end
end

defmodule ArgxTest do
  use ExUnit.Case

  import Argx

  describe "no defconfig" do
    defmodule Example1 do
      with_check configs(
                   cargoes(:list) || Argx.A.B.C.Helper.get_default_cargoes(),
                   name(:string)
                 ) do
        def create(name, cargoes) do
          {name, cargoes}
        end
      end
    end

    test "ok" do
      assert {"name", [:default_cargoes_from_fun]} == Example1.create("name", nil)
      assert {"a", []} == Example1.real_create__macro("a", [])
    end
  end

  describe "defconfig" do
    defmodule Example2 do
      defconfig(AbcRule, reason(:map, :optional))

      with_check configs(AbcRule) do
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
      defconfig(AbcRule, one(:map, :optional))
      defconfig(XyzRule, [two(:integer, :auto), three(:string, :optional)])

      with_check configs(AbcRule, XyzRule, house(:string)) do
        def get_one(one, two, three, house) do
          one <> two <> three <> house
        end
      end
    end

    test "ok" do
      assert "123a" == Example3.get_one("1", "2", "3", "a")
      assert "123a" == Example3.real_get_one__macro("1", "2", "3", "a")
    end
  end
end
