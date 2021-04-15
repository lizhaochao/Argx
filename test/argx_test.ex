defmodule Argx.A.B.C.Helper do
  @moduledoc false

  def get_default_cargoes do
    [:default_cargoes]
  end
end

defmodule MyArgx1 do
  @moduledoc false

  use Argx

  def format_errors(errors) do
    errors
  end
end

defmodule ArgxTest do
  @moduledoc false

  use ExUnit.Case

  import MyArgx1

  describe "no defconfig" do
    defmodule Example1 do
      @moduledoc false

      with_check configs(
                   cargoes(:list) || Argx.A.B.C.Helper.get_default_cargoes(),
                   number(:integer, :auto),
                   amount(:float, :auto, 1..3),
                   price(:float, :auto, :optional, 5..11)
                 ) do
        def create(number, amount, price, cargoes) do
          {number, amount, price, cargoes}
        end
      end
    end

    test "normal ok" do
      assert {1, 1.1, 10.0, [:a, :b]} == Example1.create(1, 1.1, 10.0, [:a, :b])
      assert {"11", "11.33", 18, []} == Example1.real_create__macro("11", "11.33", 18, [])
    end

    test "set default ok" do
      assert {1, 1.1, 10.0, [1]} == Example1.create(1, 1.1, 10.0, [1])
    end

    test "auto convert ok" do
      assert {1, 1.1, 10.0, [:default_cargoes]} == Example1.create(1, "1.1", 10.0, nil)
    end

    test "default && convert ok" do
      assert {1, 1.1, 10.0, [:default_cargoes]} == Example1.create(1, "1.1", 10, nil)
    end

    test "lacked" do
      assert {:error, [lacked: [:number]]} == Example1.create(nil, "1.1", "10.0", [])
      assert {:error, [lacked: [:number, :amount]]} == Example1.create(nil, nil, "10.0", [])
      assert {:error, [lacked: [:number, :amount]]} == Example1.create(nil, nil, nil, [])
    end

    test "lacked & error type" do
      assert {:error, [lacked: [:number], error_type: [:amount, :cargoes]]} ==
               Example1.create(nil, "a", nil, 1)

      assert {:error, [lacked: [:number], error_type: [:amount, :price, :cargoes]]} ==
               Example1.create(nil, "a", "b", 1)
    end

    test "lacked & error type & out of range" do
      assert {:error,
              [
                {:lacked, [:number]},
                {:error_type, [:cargoes]},
                {:out_of_range, [:amount, :price]}
              ]} == Example1.create(nil, "5.2", 3, "cargoes")
    end
  end

  describe "defconfig" do
    defmodule Example2 do
      @moduledoc false

      defconfig(AbcRule, reason(:map, :optional))

      with_check configs(AbcRule) do
        def approve(reason) do
          {reason}
        end
      end
    end

    test "ok" do
      assert {:error, [error_type: [:reason]]} == Example2.approve("name")
    end
  end

  describe "mix defconfig & with_check config" do
    defmodule Example3 do
      @moduledoc false

      defconfig(AbcRule, one(:map, :optional))
      defconfig(XyzRule, [two(:integer, :auto), three(:float, :auto)])
      defconfig(ListRule, cargoes(:list))

      with_check configs(AbcRule, XyzRule, ListRule, house(:string)) do
        def get_one(one, two, three, house, cargoes) do
          {one, two, three, house, cargoes}
          :ok
        end
      end

      def format_errors(errors) do
        {:err, errors}
      end
    end

    test "ok" do
      result = Example3.get_one(%{}, 1, 3.1, "house", [1, 2, 3])
      assert :ok == result
    end
  end
end
