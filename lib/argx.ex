defmodule Argx do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use Argx.Defconfig.Use

      use Argx.WithCheck.Use
    end
  end
end
