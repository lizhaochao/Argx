defmodule Argx.Const do
  @moduledoc false

  def store_key, do: :defconfig_key
  def allowed_types, do: [:list, :map, :string, :integer, :float]
  def allowed_functionalities, do: [:optional, :auto]
  def allowed_fun_types, do: [:def, :defp]
end
