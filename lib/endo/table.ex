defmodule Endo.Table do
  @moduledoc false
  @type t :: %__MODULE__{}
  defstruct [:adapter, :name, columns: [], associations: [], indexes: []]
end
