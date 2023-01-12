defmodule Endo.Adapters.Postgres do
  @moduledoc """
  Adapter module implementing the ability for Endo to reflect upon any
  Postgres-based Ecto Repo.

  See `Endo` documentation for list of features.

  In future, parts of `Endo`'s top level documentation may be moved here, but as
  this is the only supported adapter at the time of writing, this isn't the case.
  """

  @behaviour Endo.Adapter

  alias Endo.Adapters.Postgres.Column
  alias Endo.Adapters.Postgres.Index
  alias Endo.Adapters.Postgres.PgClass
  alias Endo.Adapters.Postgres.PgIndex
  alias Endo.Adapters.Postgres.Table
  alias Endo.Adapters.Postgres.TableConstraint

  @spec list_tables(repo :: module(), opts :: Keyword.t()) :: [Table.t()]
  def list_tables(repo, opts \\ []) when is_atom(repo) do
    preloads = [:columns, table_constraints: :constraint_column_usage]

    preload_indexes = fn %Table{table_name: name} = table ->
      indexes = PgClass.query(collate_indexes: true, relname: name)
      %Table{table | indexes: repo.all(indexes)}
    end

    opts
    |> Table.query()
    |> repo.all()
    |> Task.async_stream(&(&1 |> repo.preload(preloads) |> preload_indexes.()))
    |> Enum.map(fn {:ok, %Table{} = table} -> table end)
  end

  @spec to_endo(Table.t(), Keyword.t()) :: Endo.Table.t()
  @spec to_endo(TableConstraint.t(), Keyword.t()) :: Endo.Association.t()
  @spec to_endo(Column.t(), Keyword.t()) :: Endo.Column.t()
  @spec to_endo(Index.t(), Keyword.t()) :: Endo.Index.t()

  def to_endo(entity, config \\ [])

  def to_endo(%Table{} = table, config) do
    %Endo.Table{
      adapter: __MODULE__,
      name: table.table_name,
      columns: Enum.map(table.columns, &to_endo/1),
      indexes: Enum.map(table.indexes, &to_endo/1),
      schemas: %Endo.Schema.NotLoaded{
        table: table.table_name,
        otp_app: Keyword.get(config, :otp_app)
      },
      associations:
        table.table_constraints
        |> Enum.filter(&(&1.constraint_type == "FOREIGN KEY"))
        |> Enum.map(&to_endo/1)
    }
  end

  def to_endo(%Column{} = column, _config) do
    %Endo.Column{
      adapter: __MODULE__,
      name: column.column_name,
      type: column.data_type
    }
  end

  def to_endo(%TableConstraint{} = constraint, _config) do
    %Endo.Association{
      adapter: __MODULE__,
      name: constraint.constraint_name,
      type: constraint.constraint_column_usage.table_name
    }
  end

  def to_endo(%Index{} = index, _config) do
    metadata = index.pg_index || %PgIndex{}

    %Endo.Index{
      adapter: __MODULE__,
      name: index.name,
      columns: index.columns,
      is_primary: metadata.indisprimary,
      is_unique: metadata.indisunique
    }
  end
end
