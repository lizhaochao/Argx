defmodule Argx do
  @moduledoc false

  alias Argx.{Formatter, Defconfig, Matcher, Util}
  alias Argx.Use.Helper
  alias Argx, as: Self

  defmacro __using__(general_m) do
    quote do
      import Argx.Inner.Defconfig

      def match(%{} = args, config_names) when is_list(config_names) do
        args
        |> Enum.into([])
        |> Self.do_match(config_names, __MODULE__, unquote(general_m), :map)
      end

      def match(args, config_names) when is_list(args) and is_list(config_names) do
        Self.do_match(args, config_names, __MODULE__, unquote(general_m), :keyword)
      end

      def match(_args, _config_names) do
        raise(Argx.Error, "args must be map & config names must be list")
      end
    end
  end

  def do_match(args, config_names, current_m, general_m, origin_type) when is_list(args) do
    configs =
      current_m
      |> get_all_configs(general_m)
      |> Helper.get_configs_by_names(config_names)
      |> Enum.into([])

    new_args = Util.sort_by_keys(args, Keyword.keys(configs))

    current_m
    |> Matcher.match(new_args, configs)
    |> post_match(current_m, general_m, origin_type)
  end

  defp get_all_configs(current_m, general_m) do
    defconfigs = Defconfig.get_defconfigs(current_m)
    general_configs = Defconfig.get_defconfigs(general_m)
    Map.merge(general_configs, defconfigs)
  end

  defp post_match(result, current_m, general_m, origin_type) do
    result
    |> Formatter.fmt_match_result(origin_type)
    |> Formatter.fmt_errors(current_m, general_m)
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

  alias Argx.Const
  alias Argx.Defconfig, as: Self

  defmacro __using__(_opts) do
    quote do
      import Argx.Inner.Defconfig

      def __get_defconfigs__() do
        Self.get_defconfigs(__MODULE__)
      end
    end
  end

  def get_defconfigs(m) when is_atom(m) do
    :functions
    |> m.__info__()
    |> Enum.filter(fn {f_name, _arity} ->
      f_name |> to_string() |> Kernel.=~(to_string(Const.defconfigs_key()))
    end)
    |> Enum.reduce(%{}, fn {f_name, _arity}, general_configs ->
      configs = apply(m, f_name, [])
      Map.merge(general_configs, configs)
    end)
  end

  def get_defconfigs(_other_m), do: %{}
end
