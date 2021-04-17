defmodule Argx.Const do
  @moduledoc false

  def names_key, do: :__names__
  def defconfigs_key, do: :__defconfigs__

  def allowed_types, do: [:list, :map, :string, :integer, :float, :boolean]
  def allowed_functionalities, do: [:optional, :auto, :empty]

  def allowed_fun_types, do: [:def, :defp]
  def not_support_types, do: [:@, :defmodule, :use, :require, :import, :alias]

  def configs_keyword, do: :configs
end
