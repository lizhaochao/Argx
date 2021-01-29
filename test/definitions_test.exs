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
end
