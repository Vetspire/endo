defmodule Endo do
  @moduledoc """
  Endo is a library which allows you to reflect on the tables, columns, indexes, and
  other data stored within a given Ecto Repo.

  ## Basic Usage

  To get started with Endo, all you need is a supported Ecto Repo from your application,
  as well as the Endo dependency.

  Currently, Endo only supports the `Ecto.Adapters.Postgres` adapter, but Endo was built
  to be adapter agnostic, so additional adapters may be implemented in the future.

  Given an Ecto Repo whose adapter is `Ecto.Adapters.Postgres`, you can execute Endo with
  the following snippet:

  ```elixir
  Endo.list_tables(MyApp.Repo)
  ```

  This default invokation will return a list of all public tables in your repo's database,
  as well as metadata pertaining to said tables.

  At the time of writing, table metadata includes:

  - The name of the given table.
  - A list of columns defined in the given table.
  - A list of indexes defined in the given table.
  - A list of associations, if any, sourced from the given table.
  - The repo adapter, for reference.

  In the future, we plan on implementing a list of constraints, as well as surfacing additional
  stats and metrics which we can lift from the underlying adapters.

  > #### Note {: .info}
  >
  > By default, Endo will return *all tables in the public schema* for a Postgres repo.
  > This will include a default `schema_migrations` table which is seeded by Ecto itself.
  >
  > Additionally, if you're using dependencies such as `Oban`, any tables created for these
  > dependencies may also be returned.

  ## Complex Lookups

  By providing the optional second paramter to `Endo.list_tables/2`, you can instruct Endo to
  fetch tables matching an arbitrary set of criterion.

  Options are ultimately passed down into the Endo adapter matching the given repo module, but
  in general the supported high-level options are:

  - `with_column`, instructs Endo to only return tables which define a column with the given name
  - `without_column`, instructs Endo to only return tables which do not define a column with the
    given name
  - `with_foreign_key_constraint`, instructs Endo to only return tables which have a foreign key constraint
    to the given table name
  - `without_foreign_key_constraint`, instructs Endo to only return tables which do not have a foreign
    key constraint to the given table name
  - `with_index`, instructs Endo to only return tables with indexes on the given column or columns.
    If a list of columns if given, then we look for a compound index that exactly matches the given ones
    components and order.
  - `without_index`, instructs Endo to only return tables without indexes on the given column or columns.
    Likewise, compound indexes must exactly match the given ones components and order.
  - `with_index_covering`, instructs Endo to only return tables with an index which covers the given
    column(s). An index covering a given column(s) is defined as whether or not there exists a single index
    or composite index which contains the given column(s) regardless of ordering.
  - `without_index_covering`, instructs Endo to only return tables without an index which covers the given
    column(s). The same caveats as the above option apply.

  Additionally, adapters are free to implement custom filters. The `Endo.Adapters.Postgres` adapter
  forwards any filters not matching the above list directly to direct SQL queries against the base
  information schema tables the adapter sources from.

  This means that is it possible to perform direct queries such as `Endo.list_tables(MyApp.Repo, table_name: "payments")`.
  See `Endo.Adapters.Postgres` and `Endo.Adapters.Postgres.Table` for a list of supported fields -- though as these
  are internal to Endo, do not count on these being stable across version upgrades.

  Endo also supports multiple filters being given in a single invokation. Multiple filters will apply
  in addition to one another, in the order which they are given. The same filter can be provided multiple
  times also.

  See the following example for details:

  ```elixir
  Endo.list_tables(MyApp.Repo, with_column: "inserted_at")
  # Returns list of tables defining an `inserted_at` column.

  Endo.list_tables(MyApp.Repo, with_column: "inserted_at", without_index: "inserted_at")
  # Returns list of tables defining an `inserted_at` column that does not index said column.

  Endo.list_tables(MyApp.Repo, with_column: "inserted_at", without_column: "updated_at")
  # Returns list of tables defining an `inserted_at` column while also not defining an `updated_at` column.

  Endo.list_tables(MyApp.Repo, with_foreign_key_constraint: "cars", without_index: "car_id")
  # Returns list of tables defining a relation to `cars`, without an index on said column

  Endo.list_tables(MyApp.Repo, with_index: ["org_id", "location_id", "patient_id"])
  # Returns list of tables defining a *composite index* on `(org_id, location_id, patient_id)`
  # Tables containing the same index in a different order, or a partial match will not be returned.

  Endo.list_tables(MyApp.Repo, with_index_covering: "org_id")
  # Returns list of tables defining any index which includes `org_id` (exact matches, or there exists
  # some composite index where `org_id` is a member).
  # Ordering does not matter.
  ```

  ## Adapter-specific metadata

  While Endo is designed to be able to adapt and connect to several different database backends, it is known that
  certain features are very much database-engine specific.

  As a result of this, each `Endo.Table.t()` also surfaces potentially adapter-specific metadata by way of its
  `metadata` key.

  A piece of `metadata` will be of type `Endo.Metadata.Postgres.t()` if it surfaces from the `Endo.Adapters.Postgres`
  adapter for example. Said metadata will thus be tailored to the underlying repo database engine.

  This information is useful if one wants to build CI checks and other features on a lower level; i.e. writing
  a check that enforces all tables in your application which don't have a primary key has `REPLICA IDENTITY FULL` set
  to enable Postgres to replicate to read replicas correctly.

  See below for an example of such a check:

  ```elixir
  [] =
    Repo
    |> Endo.list_tables()
    |> Enum.reject(&Enum.any?(&1.indexes, fn index -> index.is_primary end))
    |> Enum.reject(&(&1.metadata.replica_identity == "FULL"))
  ```

  As features get built out, we make no hard guarantees of keeping the `metadata` field stable, but efforts will
  of course be taken to mitigate unnecessary breaking changes from occuring.
  """

  alias Endo.Adapters.Postgres

  @doc """
  Given an Ecto Repo and a table name, tries to return an Endo Table or nil if said table does
  not exist.

  Internally delegates to `list_tables/2` with the `table_name` option set.
  See `list_tables/2` for more information.
  """
  @spec get_table(repo :: module(), table_name :: String.t(), filters :: Keyword.t()) ::
          Endo.Table.t() | nil
  def get_table(repo, table_name, filters \\ []) when is_binary(table_name) do
    case list_tables(repo, Keyword.put(filters, :table_name, table_name)) do
      [%Endo.Table{} = endo_table] ->
        endo_table

      [] ->
        nil
    end
  end

  @doc """
  Given an Ecto Repo, returns a list of all tables, columns, associations, and indexes.
  Takes an optional keyword list of filters which filter said tables down to given constraints.
  """
  @spec list_tables(repo :: module(), filters :: Keyword.t()) :: [Endo.Table.t()]
  def list_tables(repo, filters \\ []) do
    unless function_exported?(repo, :__adapter__, 0) do
      raise ArgumentError,
        message: "Expected a module that `use`-es `Ecto.Repo`, got: `#{inspect(repo)}`"
    end

    list_tables(repo.__adapter__(), repo, filters)
  end

  defp list_tables(Ecto.Adapters.Postgres, repo, filters) do
    for table <- Postgres.list_tables(repo, filters) do
      Postgres.to_endo(table, repo.config())
    end
  end

  defp list_tables(adapter, _repo, _filters) do
    raise ArgumentError,
      message: """
      Unsupported adapter given. Supported adapters are currently: [Ecto.Adapters.Postgres].
      Given: #{inspect(adapter)}
      """
  end

  @doc """
  Given a list of Endo Tables or a single Endo Table, tries to load the application-specific Ecto Schemas
  See `Endo.Schema.load/1` for more information.
  """
  @spec load_schemas(Endo.Table.t()) :: Endo.Table.t()
  @spec load_schemas([Endo.Table.t()]) :: [Endo.Table.t()]
  defdelegate load_schemas(endo_table_or_tables), to: Endo.Schema, as: :load
end
