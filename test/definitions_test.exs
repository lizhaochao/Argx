defmodule DefinitionsTest do
  use ExUnit.Case

  import Argx

  ### No Compilation Error

  defmodule DefconfigDefinition do
    defconfig(Name, name(:list))
    defconfig(Name, name(:map))
    defconfig(Name, name(:string))
    defconfig(Name, name(:integer))
    defconfig(Name, name(:float))

    defconfig(Name, name(:list, :optional))
    defconfig(Name, name(:list, :auto))

    defconfig(Name, name(:list, :optional, :auto))
    defconfig(Name, name(:list, :auto, :optional))

    defconfig(Name, name(:list, :optional, :auto, 1..10))
    defconfig(Name, name(:list, :optional, 1..10, :auto))
    defconfig(Name, name(:list, 1..10, :optional, :auto))
    defconfig(Name, name(1..10, :list, :optional, :auto))
    defconfig(Name, name(1..10, :auto, :optional, :list))

    defconfig(Name, name(:list, 1..11))
    defconfig(Name, name(:list, 11..11))
    defconfig(Name, name(:list, 11))

    defconfig(Name, name(:list, :optional, :auto, 1..10) || "lee")
    defconfig(Name, name(:list, :optional, :auto) || "lee")
    defconfig(Name, name(:list, :optional) || "lee")

    defconfig(Name, name(:list) || "ok")
    defconfig(Name, name(:list) || :ok)
    defconfig(Name, name(:list) || 1)
    defconfig(Name, name(:list) || 1.1)
    defconfig(Name, name(:list) || [])
    defconfig(Name, name(:list) || {})
    defconfig(Name, name(:list) || (&Enum.filter/2))
    defconfig(Name, name(:list) || hello)
    defconfig(Name, name(:list) || hello())
    defconfig(Name, name(:list) || Account.get())
    defconfig(Name, name(:list) || Account.post(1))

    defconfig(Name, [name(:list, :optional, :auto, 1..10), addr(:list, :optional, :auto, 1..10)])
    defconfig(Name, [name(:list) || Account.post(1), addr(:list) || Account.post(1)])

    defconfig(Name, [
      name(:list, :optional, :auto, 1..10) || Account.post(1),
      addr(:map, :optional, :auto, 2..20) || hello()
    ])
  end

  defmodule WithCheckTest do
    with_check configs(Rule) do
      def create(name) when is_bitstring(name), do: name
    end

    with_check configs(RuleA, RuleB) do
      def get(name) when is_bitstring(name), do: name
    end

    with_check configs(name(:string), number(:integer)) do
      def change(name) when is_bitstring(name), do: name
    end

    with_check configs(Rule, number(:integer)) do
      def delete(name) when is_bitstring(name), do: name
    end

    with_check configs(RuleA, RuleB, name(:string), number(:integer)) do
      def update(name) when is_bitstring(name), do: name
    end

    with_check configs(
                 Rule,
                 name(:list, :optional, :auto, 1..10),
                 addr(:list, :optional, :auto, 1..24),
                 name2(:list) || Account.post(1),
                 addr2(:list) || Account.get("ljy")
               ) do
      def search(name) when is_bitstring(name), do: name
    end
  end
end
