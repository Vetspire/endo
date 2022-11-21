defmodule Endo.Adapter do
  @moduledoc false

  @callback list_tables(repo :: module(), filters :: Keyword.t()) :: [map()]
  @callback to_endo(data :: map()) ::
              Endo.Table.t() | Endo.Column.t() | Endo.Association.t() | Endo.Index.t()
end
