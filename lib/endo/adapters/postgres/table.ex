defmodule Endo.Adapters.Postgres.Table do
  @moduledoc false

  use Ecto.Schema
  use Endo.Queryable

  alias Endo.Adapters.Postgres.Column
  alias Endo.Adapters.Postgres.ConstraintColumnUsage
  alias Endo.Adapters.Postgres.KeyColumnUsage
  alias Endo.Adapters.Postgres.PgClass
  alias Endo.Adapters.Postgres.TableConstraint

  @type t :: %__MODULE__{}

  @schema_prefix "information_schema"
  @primary_key {:table_name, :string, []}
  schema "tables" do
    field(:table_catalog, :string)
    field(:table_schema, :string)
    field(:table_type, :string)

    field(:user_defined_type_catalog, :string)
    field(:user_defined_type_schema, :string)
    field(:user_defined_type_name, :string)

    field(:self_referencing_column_name, :string)
    field(:reference_generation, :string)

    field(:is_insertable_into, Ecto.Enum, values: [yes: "YES", no: "NO"])
    field(:is_typed, Ecto.Enum, values: [yes: "YES", no: "NO"])

    has_many(:columns, Column, foreign_key: :table_name, references: :table_name)

    has_many(:key_column_usage, KeyColumnUsage,
      foreign_key: :constraint_name,
      references: :table_name
    )

    has_many(:constraint_column_usage, ConstraintColumnUsage,
      foreign_key: :constraint_name,
      references: :table_name
    )

    has_many(:table_constraints, TableConstraint,
      foreign_key: :table_name,
      references: :table_name
    )

    field(:indexes, :map, virtual: true)
    field(:pg_class, :map, virtual: true)
    field(:size, :map, virtual: true)
  end

  @impl Endo.Queryable
  def base_query do
    from(x in __MODULE__, as: :self, where: x.table_schema == "public")
  end

  @impl Endo.Queryable
  def query(base_query \\ base_query(), filters) do
    Enum.reduce(filters, base_query, fn
      {:with_column, column_name}, query ->
        from(query, where: exists(Column.query(subquery: true, column_name: column_name)))

      {:without_column, column_name}, query ->
        from(query, where: not exists(Column.query(subquery: true, column_name: column_name)))

      {:with_foreign_key_constraint, table_name}, query ->
        constraints_query = TableConstraint.query(subquery: true, foreign_table_name: table_name)
        from(query, where: exists(constraints_query))

      {:without_foreign_key_constraint, table_name}, query ->
        constraints_query = TableConstraint.query(subquery: true, foreign_table_name: table_name)
        from(query, where: not exists(constraints_query))

      {:with_index, columns}, query ->
        indexes_query =
          PgClass.query(subquery: true, collate_indexes: true, having_index: columns)

        from(query, where: exists(indexes_query))

      {:without_index, columns}, query ->
        indexes_query =
          PgClass.query(subquery: true, collate_indexes: true, having_index: columns)

        from(query, where: not exists(indexes_query))

      {field, value}, query ->
        apply_filter(query, field, value)
    end)
  end
end
