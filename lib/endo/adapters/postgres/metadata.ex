defmodule Endo.Adapters.Postgres.Metadata do
  @moduledoc "Utility module for taking a Postgres table and exposing adapter specific metadata to Endo"
  # coveralls-ignore-start

  alias Endo.Adapters.Postgres.PgClass
  alias Endo.Adapters.Postgres.Table

  @spec derive!(Table.t()) :: Endo.Metadata.Postgres.t()
  def derive!(%Table{pg_class: pg_class, size: size}) do
    %Endo.Metadata.Postgres{
      replica_identity: replica_identity(pg_class),
      kind: kind(pg_class),
      has_triggers: pg_class.relhastriggers,
      is_populated: pg_class.relispopulated,
      is_partitioned: pg_class.relispartition,
      pg_class: pg_class,
      table_size: size.table_size,
      relation_size: size.relation_size,
      toast_size: size.toast_size,
      index_size: size.index_size
    }
  end

  defp replica_identity(%PgClass{relreplident: "d"}), do: "DEFAULT"
  defp replica_identity(%PgClass{relreplident: "n"}), do: "NOTHING"
  defp replica_identity(%PgClass{relreplident: "f"}), do: "FULL"
  defp replica_identity(%PgClass{relreplident: "i"}), do: "INDEX"
  defp replica_identity(%PgClass{relreplident: _}), do: nil

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
  defp kind(%PgClass{relkind: _}), do: nil
end
