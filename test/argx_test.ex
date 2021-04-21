defmodule Project.Argx.General do
  @moduledoc false

  use Argx.General

  defconfig(GeneralA, a(:string))
  defconfig(GeneralB, b(:integer))
  defconfig(GeneralC, [c(:list, 1..10), d(:map)])

  def fmt_errors({:error, _}), do: false
  def fmt_errors(_), do: true
end

defmodule Project do
  @moduledoc false

  use Argx, Project.Argx.General

  defconfig(OneRule, [one(:string)])
  defconfig(TwoRule, [two(:integer)])
  defconfig(ThreeRule, three(:float))

  def get(params) do
    result = match(params, [OneRule, TwoRule, ThreeRule])
    if result, do: :ok, else: :error
  end

  def post(params) do
    result = match(params, [OneRule, GeneralC])
    if result, do: :ok, else: :error
  end
end

defmodule ArgxTest do
  @moduledoc false

  use ExUnit.Case

  describe "no general defconfigs" do
    test "ok" do
      assert :ok == Project.get(%{one: "one", two: 2, three: 3.3})
      assert :ok == Project.get(one: "one", two: 2, three: 3.3)
    end

    test "error" do
      assert :error == Project.get(%{one: "one", two: 2})
      assert :error == Project.get(one: "one", three: 3.3)
    end
  end

  describe "mixed general defconfigs & defconfigs in current module" do
    test "ok" do
      assert :ok == Project.post(%{one: "one", c: [1, 2], d: %{a: 1}})
      assert :ok == Project.post(one: "one", c: [1, 2], d: %{a: 1})
    end

    test "error" do
      assert :error == Project.post(%{one: "one", c: [1, 2]})
      assert :error == Project.post(one: "one", c: true, d: %{a: 1})
    end
  end
end
