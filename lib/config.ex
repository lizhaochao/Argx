defmodule Argx.Config do
  @moduledoc false

  @enforce_keys [:type, :optional, :auto, :range, :default]
  defstruct @enforce_keys
end
