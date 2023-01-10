defmodule Endo.Index do
  @moduledoc "Index metadata for a given table's indexes"
  @type t :: %__MODULE__{}
  defstruct [:adapter, :name, is_primary: false, is_unique: false, columns: []]
end
