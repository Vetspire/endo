defmodule Endo.Metadata do
  @moduledoc "Utility module for surfacing adapter specific metadata"

  defmodule NotLoaded do
    @moduledoc false
    @type t :: %__MODULE__{}
    defstruct []
  end

  defmodule Postgres do
    @moduledoc false
    @type t :: %__MODULE__{}
    defstruct [
      :replica_identity,
      :kind,
      :has_triggers,
      :is_populated,
      :is_partitioned,
      :pg_class
    ]
  end
end
