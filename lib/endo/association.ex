defmodule Endo.Association do
  @moduledoc "Association metadata for a given table's associations"
  @type t :: %__MODULE__{}
  defstruct [:adapter, :name, :type]
end
