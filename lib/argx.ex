defmodule Argx do
  @moduledoc """

  Using DSLs to check function args.

  including 5 functionalities:
  1. set default value if arg is nil.
  2. auto convert arg value, if arg value is compatible, like: "1" to 1.
  3. check whether arg is lacked
  4. check whether arg's type is error
  5. check whether arg's length/value is out of range

  ### Usage 1:

  1. configs keyword is necessary
  2. :string declare arg's data type.
  3. :optional declare arg's value that can be nil.
  4. :auto declare that lib convert it to integer value automatically if it is compatible.
  5. 10..20 means arg value should be in 10 to 20, not equal 10 or not equal 20.
  6. || operator is used to define default value, it also be a string/number/function.

  ~~~
  with_check configs(
                 name(:string, :optional) || Module.A.B.get_ts(),
                 number(:integer, :auto, 10..20) || 10
               ) do
    def create(name, number) do
      :ok
    end
  end
  ~~~

  ### Usage 2 :

  defconfig also is a DSL that define the checking rule,
  including 2 parts:
  1. config name, must be an atom
  2. config rule, like: field_name(:string, :optional, :auto, 1..10) || 1

  you can reuse config rule by config name.

  ~~~
  defconfig(NameRule, name(:string))

  with_check configs(NameRule, number(:integer)) do
    def create(name, number) do
      :ok
    end
  end
  ~~~

  ### All DSLs
  1. defconfig
  1. with_check

  ### All Checking Data Type Values
  1.  :string
  2.  :integer
  3.  :float
  4.  :list
  5.  :map

  ### Available Range format
  1. 1..10 (1 to 10, not equal 1 or not equal 10)
  2. 10 (10 to 10, equal to 10)

  you can apply range setting to all data types.

  ### Available Default value format
  1. value, like: 1, 1.1, "default"
  2. function, like: Module.A.B.get_ts() or get_ts()

  not support fn function at present.

  ### Functionalities
  1. :optional
  2. :auto, including 3 situations:
  (1). string to integer
  (2). string to float
  (3). integer to float
  """

  defmacro __using__(_opts) do
    quote do
      use Argx.Defconfig.Use

      use Argx.WithCheck.Use
    end
  end
end
