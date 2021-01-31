defmodule Argx.Const do
  @moduledoc false

  def names_key, do: :__names__
  def defconfigs_key, do: :__defconfigs__

  def allowed_types, do: [:list, :map, :string, :integer, :float]
  def allowed_functionalities, do: [:optional, :auto]

  def allowed_fun_types, do: [:def, :defp]
end
