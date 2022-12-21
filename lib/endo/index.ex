defmodule Endo.Index do
  @moduledoc "Index metadata for a given table's indexes"
  @type t :: %__MODULE__{}
  defstruct [:adapter, :name, columns: []]
end
