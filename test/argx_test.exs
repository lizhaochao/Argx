defmodule Project.Argx.General do
  use Argx.Defconfig

  defconfig(GeneralA, a(:string))
  defconfig(GeneralB, b(:integer))
  defconfig(GeneralC, [c(:list, 1..10), d(:map)])

  def fmt_errors({:error, _}), do: false
  def fmt_errors(_), do: true
end

defmodule Project do
  use Argx, share: Project.Argx.General

  defconfig(OneRule, [one(:string)])
  defconfig(TwoRule, [two(:integer)])
  defconfig(ThreeRule, three(:float))

  def get(params) do
    result = check(params, [OneRule, TwoRule, ThreeRule])
    if result, do: :ok, else: :error
  end

  def post(params) do
    result = check(params, [OneRule, GeneralC])
    if result, do: :ok, else: :error
  end
end

defmodule YourProject do
  use Argx
  defconfig(Rule, id(:string))
  def get(args), do: check(args, [Rule])
end

defmodule ArgxTest do
  use ExUnit.Case

  doctest Argx

  test "README.md Demo" do
    assert {:error, ["error type: id"]} == YourProject.get(%{id: 1})
    assert [id: "a"] == YourProject.get(id: "a")
  end

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
