defmodule Endo.Adapters.Postgres.KeyColumnUsage do
  @moduledoc false
  use Ecto.Schema
  use Endo.Queryable

  alias Endo.Adapters.Postgres.Table
  alias Endo.Adapters.Postgres.TableConstraint

  @type t :: %__MODULE__{}

  # TODO: This table can be used in tandem with our existing index lookup logic
  #       to determine table constraints, whether or not indexes are unique, etc
  #
  #       This mapping currently exists and works, but isn't exposed by `Endo`'s
  #       top level structs, or queries. Thus we'll ignore it for the time being.
  #
  # coveralls-ignore-start

  @schema_prefix "information_schema"
  @foreign_key_type :string
  @primary_key false
  schema "key_column_usage" do
    field(:constraint_catalog, :string)
    field(:constraint_schema, :string)
    field(:column_name, :string)

    field(:table_catalog, :string)
    field(:table_schema, :string)

    field(:ordinal_position, :integer)
    field(:position_in_unique_constraint, :integer)

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
