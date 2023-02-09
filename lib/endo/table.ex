defmodule Endo.Table do
  @moduledoc "Table metadata returned by Endo."
  @type t :: %__MODULE__{}
  defstruct [
    :adapter,
    :name,
    columns: [],
    associations: [],
    indexes: [],
    schemas: %Endo.Schema.NotLoaded{},
    metadata: %Endo.Metadata.NotLoaded{}
  ]
end
