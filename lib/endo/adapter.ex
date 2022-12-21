defmodule Endo.Adapter do
  @moduledoc """
  Module defining the `Endo.Adapter` behaviour. Valid adapters will allow Endo to reflect
  upon a module implementing said adater
  """

  @callback list_tables(repo :: module(), filters :: Keyword.t()) :: [map()]
  @callback to_endo(data :: map()) ::
              Endo.Table.t() | Endo.Column.t() | Endo.Association.t() | Endo.Index.t()
end
