defmodule Endo.Index do
  @moduledoc false
  @type t :: %__MODULE__{}
  defstruct [:adapter, :name, columns: []]
end
