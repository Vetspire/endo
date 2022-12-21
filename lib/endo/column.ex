defmodule Endo.Column do
  @moduledoc "Column metadata for a given table's columns"
  @type t :: %__MODULE__{}
  defstruct [:adapter, :name, :type]
end
