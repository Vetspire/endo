defmodule Endo.Adapters.Postgres.Metadata do
  @moduledoc "Utility module for taking a Postgres table and exposing adapter specific metadata to Endo"
  # coveralls-ignore-start

  alias Endo.Adapters.Postgres.PgClass
  alias Endo.Adapters.Postgres.Table

  @spec derive!(Table.t()) :: Endo.Metadata.Postgres.t()
  def derive!(%Table{pg_class: nil} = table) do
    %Endo.Metadata.NotAvailable{
      table: table.table_name,
      adapter: Endo.Adapters.Postgres,
      message: "Could not find `pg_class` for table."
    }
  end

  def derive!(%Table{pg_class: pg_class, size: size}) do
    pg_class = (is_map(pg_class) && pg_class) || %{}
    size = (is_map(size) && size) || %{}

    %Endo.Metadata.Postgres{
      replica_identity: replica_identity(pg_class),
      kind: kind(pg_class),
      has_triggers: Map.get(pg_class, :relhastriggers),
      is_populated: Map.get(pg_class, :relispopulated),
      is_partitioned: Map.get(pg_class, :relispartition),
      pg_class: pg_class,
      table_size: Map.get(size, :table_size),
      relation_size: Map.get(size, :relation_size),
      toast_size: Map.get(size, :toast_size),
      index_size: Map.get(size, :index_size),
      table_size_pretty: Map.get(size, :table_size_pretty),
      relation_size_pretty: Map.get(size, :relation_size_pretty),
      toast_size_pretty: Map.get(size, :toast_size_pretty),
      index_size_pretty: Map.get(size, :index_size_pretty)
    }
  end

  defp replica_identity(%PgClass{relreplident: "d"}), do: "DEFAULT"
  defp replica_identity(%PgClass{relreplident: "n"}), do: "NOTHING"
  defp replica_identity(%PgClass{relreplident: "f"}), do: "FULL"
  defp replica_identity(%PgClass{relreplident: "i"}), do: "INDEX"
  defp replica_identity(_otherwise), do: nil

  defp kind(%PgClass{relkind: "r"}), do: "ordinary table"
  defp kind(%PgClass{relkind: "i"}), do: "index"
  defp kind(%PgClass{relkind: "S"}), do: "sequence"
  defp kind(%PgClass{relkind: "t"}), do: "TOAST table"
  defp kind(%PgClass{relkind: "v"}), do: "view"
  defp kind(%PgClass{relkind: "m"}), do: "materialized view"
  defp kind(%PgClass{relkind: "c"}), do: "composite type"
  defp kind(%PgClass{relkind: "f"}), do: "foreign table"
  defp kind(%PgClass{relkind: "p"}), do: "partitioned table"
  defp kind(%PgClass{relkind: "I"}), do: "partitioned index"
  defp kind(_otherwise), do: nil
end
