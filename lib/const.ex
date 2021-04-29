defmodule Argx.Const do
  @moduledoc false

  def names_key, do: :__names__
  def defconfigs_key, do: :__defconfigs__
  def value_key, do: :_

  def allowed_types, do: [:list, :map, :string, :integer, :float, :boolean]
  def allowed_functionalities, do: [:optional, :auto, :empty]
  def allowed_fun_types, do: [:def, :defp]
  def not_support_types, do: [:@, :defmodule, :use, :require, :import, :alias]
  def check_types, do: [:error_type, :lacked, :out_of_range]

  def should_drop_flag, do: :should_drop
  def configs_keyword, do: :configs

  def default_warn, do: true
  def warn_max_nested_depth, do: 3
end
