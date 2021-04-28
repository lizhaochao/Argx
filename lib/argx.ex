defmodule Argx do
  @moduledoc false

  import Argx.Util

  alias Argx.{Checker, Config, Formatter, Matcher}
  alias Argx.Matcher.Helper
  alias Argx, as: Self

  defmacro __using__(general_m) do
    quote do
      import Argx.Inner.Defconfig

      def match(args, config_names) do
        Self.match(args, config_names, __MODULE__, unquote(general_m))
      end
    end
  end

  def match(args, config_names, curr_m, general_m) do
    Checker.check_args!(args)
    Checker.check_config_names!(config_names)

    with origin_type <- get_type(args),
         configs <- get_configs(general_m, curr_m, config_names),
         {args, configs} <- Helper.pre_args_configs(args, configs) do
      match = Matcher.from(:argx)

      match.(args, configs, curr_m)
      |> Formatter.fmt_match_result(origin_type)
      |> Formatter.fmt_errors(curr_m, general_m)
    end
  end

  def get_configs(general_m, curr_m, config_names) do
    [general_m, curr_m]
    |> Config.get_configs_by_modules()
    |> Config.get_configs_by_names(config_names)
    |> Enum.into([])
  end
end

defmodule Argx.WithCheck do
  @moduledoc """

  A DSL for validating function's args.

  including 5 functionalities:
  - set default value if arg is ```nil```.
  - convert arg's value automatically, if arg's value is compatible, like: ```"1"``` to ```1```.
  - check whether arg is lacked
  - check whether arg's type is error
  - check whether arg's length/value is out of range

  ### Validator
  We can define a validator as follows:

  ```
  defmodule Project.Util.Validator do
    use Argx
  end
  ```

  ### Usage 1:

  - ```configs``` keyword is necessary
  - ```:string``` declare arg's data type.
  - ```:optional``` declare arg's value that can be nil.
  - ```:auto``` declare that lib convert it to integer value automatically if it is compatible.
  - ```10..20``` means arg value should be in 10 to 20, not equal 10 or not equal 20.
  - ```||``` operator is used to define default value, it also be a value/function.

  ```
  defmodule Project.A.B do
    import Project.Util.Validator

    with_check configs(
                   name(:string, :optional) || Module.A.B.get_ts(),
                   number(:integer, :auto, 10..20) || 10
                 ) do
      def create(name, number) do
        :ok
      end
    end
  end
  ```

  ### Usage 2 :

  defconfig also is a DSL that define the checking rule,
  including 2 parts:
  - config name, must be an atom
  - config rule, like: ```arg_name(:string, :optional, :auto, 1..10) || 1```

  we can reuse config rule by config name.

  ```
  defmodule Project.A.B do
    import Project.Util.Validator

    defconfig(NameRule, name(:string))

    with_check configs(NameRule, number(:integer)) do
      def create(name, number) do
        :ok
      end
    end
  end
  ```

  ### Callback

  ```fmt_errors/1```

  we can define in 2 places.
  ```
  defmodule Project.A.B do
    ...

    with_check configs(NameRule, number(:integer)) do
      def create(name, number) do
        :ok
      end
    end

    # higher priority
    def fmt_errors(errors) do
      errors
    end
  end
  ```

  ```
  defmodule Project.Util.Validator do
    use Argx

    def fmt_errors(errors) do
      {:error, 1000, errors}
    end
  end
  ```

  ### All DSLs
  - ```defconfig```
  - ```with_check```

  ### All Checking Data Type Values
  -  ```:string```
  -  ```:integer```
  -  ```:float```
  -  ```:list```
  -  ```:map```

  ### Available Range format
  - ```1..10``` (1 to 10, not equal 1 or not equal 10)
  - ```10``` (10 to 10, equal to 10)

  you can apply range setting to all data types.

  ### Available Default value format
  - value, like: ```1```, ```1.1```, ```"default"```
  - function, like: ```Module.A.B.get_ts()``` or ```get_ts()```

  not support ```fn``` function at present.

  ### Functionalities
  - ```:optional```
  - ```:auto```, including 3 situations:
  (1). string to integer
  (2). string to float
  (3). integer to float
  """

  defmacro __using__(general_m) do
    quote do
      use Argx.Use.Defconfig
      use Argx.Use.WithCheck, unquote(general_m)
    end
  end
end

defmodule Argx.Defconfig do
  @moduledoc false

  alias Argx.Config

  defmacro __using__(_opts) do
    quote do
      import Argx.Inner.Defconfig

      def __get_defconfigs__() do
        Config.get_defconfigs(__MODULE__)
      end
    end
  end
end
