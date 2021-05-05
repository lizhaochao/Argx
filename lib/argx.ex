defmodule Argx do
  @moduledoc """
  DSLs for checking args.
  ## Usage
  ### Quick Start
  ```elixir
  defmodule YourProject do
    # step 1: introduce check function by Argx module
    use Argx

    # step 2: define rule
    defconfig(Rule, id(:string))

    def get(args) do
      # step 3: use check function to check args
      check(args, [Rule])
      |> case do
        [] -> :ok
        _ -> :error
      end
    end
  end
  ```
  ### Check Via DSL
  ```elixir
  # step 1: define your validator
  defmodule YourProject.Argx do
    use Argx.WithCheck
  end

  defmodule YourProject do
    # step 2: import your validator
    import YourProject.Argx

    # step 3: use with_check macro to wrap your function
    with_check configs(id(:string)) do
      def get(id) do
        {id}
      end
    end
  end
  ```
  ## Advanced
  ### 1. How to share arg configs?
  **step 1**: create a module for define shared arg configs.
  ```elixir
  defmodule YourProject.ArgConfigs do
    use Argx.Defconfig
    defconfig(NumberRule, number(:string, :empty))
    defconfig(PageSizeRule, page_size(:integer, :auto, 1..100) || 10)
  end
  ```
  **step 2** : config share module to the following positions.
  ```elixir
  use Argx, share: YourProject.ArgConfigs
  # or
  use Argx.WithCheck, share: YourProject.ArgConfigs
  ```
  **step 3** : use arg config by name.
  ```elixir
  def get(args) do
    check(args, [NumberRule, PageSizeRule])
    |> case do
      [] -> :ok
      _ -> :error
    end
  end
  # or
  with_check configs(NumberRule, PageSizeRule) do
    def get(id) do
      {id}
    end
  end
  ```
  ### 2. Format errors
  just implement callback `fmt_errors/1`, Argx invoke your custom format errors function, when check done.

  There are 3 places to put it.

  **Highest priority**: in the current module.
  ```elixir
  defmodule YourProject do
    use Argx
    def fmt_errors({:error, _errors}), do: :error
    def fmt_errors(_new_args_or_result), do: :ok
    ...
  end
  # or
  defmodule YourProject do
    import YourProject.Argx
    def fmt_errors({:error, _errors}), do: :error
    def fmt_errors(_new_args_or_result), do: :ok
    ...
  end
  ```
  **Second priority**: in the share arg configs module.
  ```elixir
  defmodule YourProject.ArgConfigs do
    use Argx.Defconfig
    def fmt_errors({:error, _errors}), do: :error
    def fmt_errors(_new_args_or_result), do: :ok
    ...
  end
  ```
  **Lowest priority**: if you use argx via with_check, also implement it in the definition module.
  ```elixir
  defmodule YourProject.Argx do
    use Argx.WithCheck
    def fmt_errors({:error, _errors}), do: :error
    def fmt_errors(_new_args_or_result), do: :ok
    ...
  end
  ```

  ## Features
  - set default value if arg is ```nil``` or empty.
  - convert arg's value automatically, if arg's value is compatible, such as: ```"1"``` to ```1```.
  - check whether arg is lacked or empty.
  - check whether arg's type is error.
  - check whether arg's length/value is out of range.
  - support nested data checking.

  ## Support Data Type
    -  ```:boolean```
    -  ```:integer```
    -  ```:float```
    -  ```:string```
    -  ```:list```
    -  ```:map```

  ## check/2 function
  - meaning of function's arg:
    - first arg only accept map or keyword data type as checking args.
    - second arg must be a list that only contains one or more rule names.
    ```elixir
    check(data, [RuleA, :RuleB, "RuleC"])
    ```
  - return value:
    - return new args, if success.
    - return errors, if failure.

  ## Configuration
  config `Argx` or `Argx.WithCheck` module.
  1. set shared arg configs module.
  2. set warn flag.
  ```elixir
  use Argx, share: YourProject.ArgConfigs, warn: false
  ```
  """

  defmacro __using__(opts) do
    quote do
      import Argx.Inner.Defconfig
      use Argx.Use, unquote(opts)
    end
  end
end

defmodule Argx.WithCheck do
  @moduledoc """
  ## Usage
  - `configs` keyword is necessary and it's content is not empty.
  - define configs directly or reuse rules by name.
  - wrap multi functions that have different guards.
    ```elixir
    defmodule YourProject do
      import YourProject.Argx

      with_check configs(
                     Rule,
                     id(:integer, :optional, :auto, :empty, 1..99) || get_default_id()
                 ) do
        def get(id) when is_integer(id) do
          {:ok, id}
        end
        def get(id) when is_bitstring(id) do
          {:ok, String.to_integer(id)}
        end
      end
    end
    ```

  ## Configuration
  config `Argx` or `Argx.WithCheck` module.
  1. set shared arg configs module.
  2. set warn flag.
  ```elixir
  use Argx.WithCheck, share: YourProject.ArgConfigs, warn: false
  ```
  """

  defmacro __using__(shared_m) do
    quote do
      use Argx.Use.Defconfig
      use Argx.Use.WithCheck, unquote(shared_m)
    end
  end
end

defmodule Argx.Defconfig do
  @moduledoc """
  Reuse arg config rule by name.
  - **config name**, **arg name** and **type** are necessary.
    ```elixir
    defconfig(Rule, id(:integer))
    ```
    - `Rule` is config name. `:Rule`, `Rule` or `"Rule"` are acceptable.
    - `id` is arg name.
    - `:string` is type.
  - `:optional` declare arg's value that can be nil.
    ```elixir
    defconfig(Rule, id(:integer, :optional))
    ```
  - `:auto` declare that argx convert it to integer value automatically if it is compatible.
    - `"1"` to `1`
    - `"1.2"` to `1.2`
    - `1` to `1.0`
    - `1` to `true`
    - `0` to `false`
    - `"1"` to `true`
    - `"0"` to `false`
    ```elixir
    defconfig(Rule, id(:integer, :auto))
    ```
  - `:empty` empty value the same as nil, the following values are empty.
    - `0`
    - `0.0`
    - `""`
    - `%{}`
    - `[]`
    ```elixir
    defconfig(Rule, id(:integer, :empty))
    ```
  - **range**: there are 2 ways to set value's range.
    - `10..20`, between 10 and 20, also include begin value and end value.
    - `20`, equal to 20.
    ```elixir
    defconfig(Rule, id(:integer, 10..20))
    ```
    `:list`, `:map` and `:string` value calculate it's length or size.
    `:integer` and `:float` value compare it's value directly.
    `:boolean` value will be ignored.
  - **default**: there are 3 ways to set value's default value.
    - a value, such as: `1`.
    - local function.
    - remote function, module name should be fully-qualified name, such as: `YourProject.Helper`.
    ```elixir
    defconfig(Rule, id(:integer) || 0)
    defconfig(Rule, id(:integer) || get_default_id())
    defconfig(Rule, id(:integer) || YourProject.Helper.get_default_id())
    ```
  - **multi configs**: define them in one rule.
    ```elixir
    defconfig(Rule, [id(:integer), name(:string)])
    ```
  """

  alias Argx.{Config, Const}

  @defconfigs_key Const.defconfigs_key()

  defmacro __using__(_opts) do
    quote do
      import Argx.Inner.Defconfig

      def __get_defconfigs__() do
        Config.get_defconfigs(__MODULE__, unquote(@defconfigs_key))
      end
    end
  end
end
