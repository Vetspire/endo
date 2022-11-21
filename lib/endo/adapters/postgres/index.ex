defmodule Endo.Adapters.Postgres.Index do
  @moduledoc false
  @type t :: %__MODULE__{}
  defstruct [:columns, :name]
end
