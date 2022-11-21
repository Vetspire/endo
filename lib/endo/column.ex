defmodule Endo.Column do
  @moduledoc false
  @type t :: %__MODULE__{}
  defstruct [:adapter, :name, :type]
end
