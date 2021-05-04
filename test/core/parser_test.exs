ParserTest.Use |> defmodule(do: defmacro(__using__, do: nil))
ParserTest.Default |> defmodule(do: def(get_default, do: 1_618_650_000))

defmodule ParserTest do
  use ExUnit.Case

  import Argx.Const

  alias Argx.Parser, as: P

  @allowed_types allowed_types()

  ###
  describe "parse_fun/1 one def function" do
    test "one line syntax with guard" do
      block =
        quote do
          def get(name) when is_bitstring(name), do: name
        end

      result = P.parse_fun(block)
      assert_parse_fun_result(result)
    end

    test "guard" do
      block =
        quote do
          def get(name) when is_bitstring(name) do
            name
          end
        end

      result = P.parse_fun(block)
      assert_parse_fun_result(result)
    end

    test "no guard" do
      block =
        quote do
          def get(name), do: name
        end

      result = P.parse_fun(block)
      assert_parse_fun_result(result)
    end
  end

  describe "parse_fun/1 one defp function" do
    test "one line syntax with guard" do
      block =
        quote do
          defp get(name) when is_bitstring(name), do: name
        end

      result = P.parse_fun(block)
      assert_parse_fun_result(result)
    end

    test "guard" do
      block =
        quote do
          defp get(name) when is_bitstring(name) do
            name
          end
        end

      result = P.parse_fun(block)
      assert_parse_fun_result(result)
    end

    test "no guard" do
      block =
        quote do
          defp get(name), do: name
        end

      result = P.parse_fun(block)
      assert_parse_fun_result(result)
    end
  end

  describe "parse_fun/1 two function" do
    test "guard" do
      m = __MODULE__

      block =
        quote do
          def get(name) when is_bitstring(name), do: name
          def get(names) when is_list(names), do: names
        end

      result = P.parse_fun(block)

      assert [
               %{
                 a: [{:name, [], m}],
                 block: {:name, [], m},
                 f: :get,
                 guard: {:is_bitstring, [context: m, import: Kernel], [{:name, [], m}]}
               },
               %{
                 a: [{:names, [], m}],
                 block: {:names, [], m},
                 f: :get,
                 guard: {:is_list, [context: m, import: Kernel], [{:names, [], m}]}
               }
             ]
             |> MapSet.new() == MapSet.new(result)
    end

    test "no guard" do
      m = __MODULE__

      block =
        quote do
          defp get(name), do: name
          defp get(name), do: name
        end

      result = P.parse_fun(block)

      assert [
               %{
                 a: [{:name, [], m}],
                 block: {:name, [], m},
                 f: :get,
                 guard: true
               },
               %{
                 a: [{:name, [], m}],
                 block: {:name, [], m},
                 f: :get,
                 guard: true
               }
             ] == result
    end
  end

  describe "parse_fun/1 error" do
    test "module attribute" do
      block =
        quote do
          @argx :argx
        end

      assert_raise Argx.Error, fn ->
        P.parse_fun(block)
      end
    end

    test "defmodule" do
      block =
        quote do
          defmodule NotSupport, do: nil
        end

      assert_raise Argx.Error, fn ->
        P.parse_fun(block)
      end
    end

    test "use" do
      block =
        quote do
          use ParserTest.Use
        end

      assert_raise Argx.Error, fn ->
        P.parse_fun(block)
      end
    end

    test "require" do
      block =
        quote do
          require ParserTest.Use
        end

      assert_raise Argx.Error, fn ->
        P.parse_fun(block)
      end
    end

    test "import" do
      block =
        quote do
          import ParserTest.Use
        end

      assert_raise Argx.Error, fn ->
        P.parse_fun(block)
      end
    end

    test "alias" do
      block =
        quote do
          alias ParserTest.Use
        end

      assert_raise Argx.Error, fn ->
        P.parse_fun(block)
      end
    end
  end

  ###
  describe "parse_configs/1 - defconfig - ok" do
    test "type" do
      @allowed_types
      |> Enum.each(fn type ->
        expr = quote do: name(unquote(type))

        assert %{
                 name: %Argx.Config{
                   auto: false,
                   default: nil,
                   optional: false,
                   range: nil,
                   type: type,
                   empty: false,
                   nested: nil
                 }
               } == P.parse_configs(expr)
      end)
    end

    test "type & optional" do
      @allowed_types
      |> Enum.each(fn type ->
        expr = quote do: name(unquote(type), :optional)

        assert %{
                 name: %Argx.Config{
                   auto: false,
                   default: nil,
                   optional: true,
                   range: nil,
                   type: type,
                   empty: false,
                   nested: nil
                 }
               } == P.parse_configs(expr)
      end)
    end

    test "type & optional & auto" do
      @allowed_types
      |> Enum.each(fn type ->
        expr = quote do: name(unquote(type), :optional, :auto)

        assert %{
                 name: %Argx.Config{
                   auto: true,
                   default: nil,
                   optional: true,
                   range: nil,
                   type: type,
                   empty: false,
                   nested: nil
                 }
               } == P.parse_configs(expr)
      end)
    end

    test "type & optional & auto & range" do
      @allowed_types
      |> Enum.each(fn type ->
        expr1 = quote do: name(unquote(type), :optional, :auto, 22)
        expr2 = quote do: name(unquote(type), :optional, :auto, 1..11)

        expr = [expr1, expr2]
        expected_range = [22, {:.., [context: __MODULE__, import: Kernel], [1, 11]}]

        0..1
        |> Enum.each(fn idx ->
          %{
            name: %Argx.Config{
              auto: true,
              default: nil,
              optional: true,
              range: parsed_range,
              type: parsed_type,
              empty: false,
              nested: nil
            }
          } = P.parse_configs(Enum.at(expr, idx))

          assert type == parsed_type
          assert Enum.at(expected_range, idx) == parsed_range
        end)
      end)
    end

    test "type & optional & auto & range & default" do
      @allowed_types
      |> Enum.each(fn type ->
        fun_expr1 = quote do: get_curr_ts()
        fun_expr2 = quote do: ParserTest.Default.get_default()
        functions = [fun_expr1, fun_expr2]
        values = [1, 1.1, "default", :default, [1, 2], %{a: 1}, {3, 4, 5, 6}]

        (values ++ functions)
        |> Enum.each(fn default ->
          expr = quote do: name(unquote(type), :optional, :auto, 33) || unquote(default)

          assert %{
                   name: %Argx.Config{
                     auto: true,
                     default: default,
                     optional: true,
                     range: 33,
                     type: type,
                     empty: false,
                     nested: nil
                   }
                 } == P.parse_configs(expr)
        end)
      end)
    end

    test "config item random order" do
      expr1 = quote do: name(:list, :optional, :auto, 1..11) || 99
      expr2 = quote do: name(:optional, :auto, 1..11, :list) || 99
      expr3 = quote do: name(:auto, 1..11, :optional, :list) || 99
      expr4 = quote do: name(1..11, :auto, :list, :optional) || 99
      expr5 = quote do: name(:optional, :auto, :list, 1..11) || 99

      [expr1, expr2, expr3, expr4, expr5]
      |> Enum.each(fn expr ->
        assert %{
                 name: %Argx.Config{
                   auto: true,
                   default: 99,
                   optional: true,
                   range: {:.., [context: __MODULE__, import: Kernel], [1, 11]},
                   type: :list,
                   empty: false,
                   nested: nil
                 }
               } == P.parse_configs(expr)
      end)
    end

    test "nested - different type rule name" do
      expr1 = quote do: name({:list, RuleA}, :optional, :auto, 1..11) || 99
      expr2 = quote do: name({:list, :RuleA}, :optional, :auto, 1..11) || 99
      expr3 = quote do: name({:list, "RuleA"}, :optional, :auto, 1..11) || 99

      [expr1, expr2, expr3]
      |> Enum.each(fn expr ->
        assert %{
                 name: %Argx.Config{
                   auto: true,
                   default: 99,
                   optional: true,
                   range: {:.., [context: __MODULE__, import: Kernel], [1, 11]},
                   type: :list,
                   empty: false,
                   nested: :RuleA
                 }
               } == P.parse_configs(expr)
      end)
    end
  end

  describe "parse_configs/1 - defconfig - error" do
    test "unknown type" do
      assert_raise Argx.Error, fn ->
        expr = quote do: name(:unknown_type, :optional)
        P.parse_configs(expr)
      end
    end

    test "unknown config item" do
      assert_raise Argx.Error, fn ->
        expr = quote do: name(:list, :opppppp)
        P.parse_configs(expr)
      end
    end
  end

  describe "parse_configs/1 - configs - ok" do
    test "only config names" do
      expr1 = quote do: configs(RuleA)
      assert %{__names__: [:RuleA]} == P.parse_configs(expr1)

      expr2 = quote do: configs(RuleA, RuleA)
      assert %{__names__: [:RuleA]} == P.parse_configs(expr2)

      expr3 = quote do: configs(RuleA, RuleB)
      %{__names__: result_names} = P.parse_configs(expr3)
      assert MapSet.new([:RuleB, :RuleA]) == MapSet.new(result_names)
    end

    test "only configs" do
      expr1 = quote do: configs(name(:string))
      expr2 = quote do: configs(name(:string), name(:list))
      expr3 = quote do: configs(name(:string), house(:map))

      assert %{
               name: %Argx.Config{
                 auto: false,
                 default: nil,
                 optional: false,
                 range: nil,
                 type: :string,
                 empty: false,
                 nested: nil
               }
             } == P.parse_configs(expr1)

      assert %{
               name: %Argx.Config{
                 auto: false,
                 default: nil,
                 optional: false,
                 range: nil,
                 type: :list,
                 empty: false,
                 nested: nil
               }
             } == P.parse_configs(expr2)

      assert %{
               house: %Argx.Config{
                 auto: false,
                 default: nil,
                 optional: false,
                 range: nil,
                 type: :map,
                 empty: false,
                 nested: nil
               },
               name: %Argx.Config{
                 auto: false,
                 default: nil,
                 optional: false,
                 range: nil,
                 type: :string,
                 empty: false,
                 nested: nil
               }
             } == P.parse_configs(expr3)
    end

    test "mixed names and configs" do
      expr = quote do: configs(RuleA, RuleB, name(:string), house(:map))

      assert %{
               name: %Argx.Config{
                 auto: false,
                 default: nil,
                 optional: false,
                 range: nil,
                 type: :string,
                 empty: false,
                 nested: nil
               },
               house: %Argx.Config{
                 auto: false,
                 default: nil,
                 optional: false,
                 range: nil,
                 type: :map,
                 empty: false,
                 nested: nil
               },
               __names__: [:RuleA, :RuleB]
             } == P.parse_configs(expr)
    end

    test "config item random order" do
      expr = quote do: configs(name(:string), RuleB, house(:map), RuleA)

      assert %{
               name: %Argx.Config{
                 auto: false,
                 default: nil,
                 optional: false,
                 range: nil,
                 type: :string,
                 empty: false,
                 nested: nil
               },
               house: %Argx.Config{
                 auto: false,
                 default: nil,
                 optional: false,
                 range: nil,
                 type: :map,
                 empty: false,
                 nested: nil
               },
               __names__: [:RuleA, :RuleB]
             } == P.parse_configs(expr)
    end
  end

  describe "parse_configs/1 - configs - error" do
    test "empty" do
      assert_raise Argx.Error, fn ->
        expr = quote do: configs()
        P.parse_configs(expr)
      end
    end
  end

  ###
  describe "parse_defconfig_name/1 - ok" do
    test "module name" do
      expr1 = quote do: TestConfigName
      assert :TestConfigName == P.parse_defconfig_name(expr1)

      expr2 = quote do: Test.ConfigName
      assert :Test_ConfigName == P.parse_defconfig_name(expr2)

      expr3 = quote do: Test.Config.Name
      assert :Test_Config_Name == P.parse_defconfig_name(expr3)
    end

    test "atom" do
      assert :config_name == P.parse_defconfig_name(:config_name)
    end

    test "string" do
      assert :config_name == P.parse_defconfig_name("config_name")
    end
  end

  describe "parse_defconfig_name/1 - error" do
    test "anonymous function" do
      assert_raise Argx.Error, fn ->
        expr1 = quote do: fn x -> x end
        P.parse_defconfig_name(expr1)
      end
    end

    test "integer & float & list & map" do
      assert_raise Argx.Error, fn ->
        P.parse_defconfig_name(1)
      end

      assert_raise Argx.Error, fn ->
        P.parse_defconfig_name(1.23)
      end

      assert_raise Argx.Error, fn ->
        list_expr = quote do: [1, 2, 3]
        P.parse_defconfig_name(list_expr)
      end

      assert_raise Argx.Error, fn ->
        map_expr = quote do: %{a: 1, b: 2}
        P.parse_defconfig_name(map_expr)
      end
    end
  end

  ###
  describe "parse_range/1 - ok" do
    test "number" do
      assert [1, 1] == P.parse_range(1)
      assert [1.23, 1.23] == P.parse_range(1.23)
    end

    test "range" do
      expr1 = quote do: 1..2

      assert [1, 2] == P.parse_range(expr1)
    end
  end

  describe "parse_range/1 - error" do
    test "list" do
      assert_raise Argx.Error, fn ->
        expr = quote do: [1, 2, 3]
        P.parse_range(expr)
      end
    end

    test "map" do
      assert_raise Argx.Error, fn ->
        expr = quote do: %{a: 1}
        P.parse_range(expr)
      end
    end
  end

  ### Assertions
  def assert_parse_fun_result(result) do
    [
      %{
        f: f,
        a: a,
        guard: guard,
        block: block
      }
    ] = result

    m = __MODULE__

    assert :get = f
    assert [{:name, [], m}] == a
    assert {:is_bitstring, [context: m, import: Kernel], [{:name, [], m}]} == guard or guard
    assert {:name, [], m} == block
  end

  ###
  def get_curr_ts, do: 1_618_653_110
end
