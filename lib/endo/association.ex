defmodule Endo.Association do
  @moduledoc false
  @type t :: %__MODULE__{}
  defstruct [:adapter, :name, :type]
end
