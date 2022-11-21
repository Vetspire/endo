defmodule Endo.Adapters.Postgres.ConstraintColumnUsage do
  @moduledoc false

  use Ecto.Schema
  use Endo.Queryable

  alias Endo.Adapters.Postgres.Table
  alias Endo.Adapters.Postgres.TableConstraint

  @type t :: %__MODULE__{}

  @schema_prefix "information_schema"
  @foreign_key_type :string
  @primary_key false
  schema "constraint_column_usage" do
    field(:column_name, :string)
    field(:constraint_catalog, :string)
    field(:constraint_schema, :string)
    field(:table_catalog, :string)
    field(:table_schema, :string)

    belongs_to(:table_constraint, TableConstraint,
      foreign_key: :constraint_name,
      references: :constraint_name,
      primary_key: true
    )

    belongs_to(:table, Table,
      foreign_key: :table_name,
      references: :table_name,
      primary_key: true
    )
  end
end
