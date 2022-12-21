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
  # Returns list of tables defining a *compound index* on `(org_id, location_id, patient_id)`
  # Tables containing the same index in a different order, or a partial match will not be returned.
  ```
  """

  alias Endo.Adapters.Postgres

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
    repo
    |> Postgres.list_tables(filters)
    |> Enum.map(&Postgres.to_endo/1)
  end

  defp list_tables(adapter, _repo, _filters) do
    raise ArgumentError,
      message: """
      Unsupported adapter given. Supported adapters are currently: [Ecto.Adapters.Postgres].
      Given: #{inspect(adapter)}
      """
  end
end
