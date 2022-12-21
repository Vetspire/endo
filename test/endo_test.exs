defmodule EndoTest do
  use ExUnit.Case

  setup_all do
    Logger.configure(level: :error)
    {:ok, find: fn tables, name -> Enum.find(tables, &(&1.name == name)) end}
  end

  describe "list_tables/2" do
    test "returns error when given non-ecto repo" do
      assert_raise(
        ArgumentError,
        "Expected a module that `use`-es `Ecto.Repo`, got: `Enum`",
        fn -> Endo.list_tables(Enum) end
      )
    end

    test "returns error when given ecto repo, but unsupported adapter" do
      assert_raise(
        ArgumentError,
        """
        Unsupported adapter given. Supported adapters are currently: [Ecto.Adapters.Postgres].
        Given: :test_adapter
        """,
        fn -> Endo.list_tables(Test.BadRepo) end
      )
    end
  end

  describe "list_tables/2 (Postgres)" do
    test "lists tables and metadata when given valid repo", ctx do
      assert tables = Endo.list_tables(Test.Postgres.Repo)

      assert Enum.count(tables) == 5

      assert %Endo.Table{} = schema_migrations = ctx.find.(tables, "schema_migrations")
      assert %Endo.Table{} = orgs = ctx.find.(tables, "orgs")
      assert %Endo.Table{} = _accounts = ctx.find.(tables, "accounts")
      assert %Endo.Table{} = accounts_orgs = ctx.find.(tables, "accounts_orgs")
      assert %Endo.Table{} = repos = ctx.find.(tables, "repos")

      # By default, the standard ecto `schema_migrations` table is created for us and is public. Endo does not
      # filter it by default.
      # It does prove to be a simple table though, so serves us well in tests like so:
      assert Enum.count(schema_migrations.associations) == 0
      assert Enum.count(schema_migrations.indexes) == 1
      assert Enum.count(schema_migrations.columns) == 2

      assert %Endo.Column{name: "version", type: "bigint"} =
               ctx.find.(schema_migrations.columns, "version")

      assert %Endo.Column{name: "inserted_at", type: "timestamp without time zone"} =
               ctx.find.(schema_migrations.columns, "inserted_at")

      assert %Endo.Index{name: "schema_migrations_pkey"} =
               ctx.find.(schema_migrations.indexes, "schema_migrations_pkey")

      # Likewise, the `orgs` table we create in our migrations is pretty simple:
      assert Enum.count(orgs.associations) == 0
      assert Enum.count(orgs.indexes) == 1
      assert Enum.count(orgs.columns) == 4

      for col <- ["inserted_at", "updated_at", "name", "id"],
          do: refute(is_nil(ctx.find.(orgs.columns, col)))

      # However, `accounts_orgs` is a many-to-many join table, and thus has two associations.
      # Association metadata is also surfaced:
      assert Enum.count(accounts_orgs.associations) == 2

      assert %Endo.Association{name: "accounts_orgs_account_id_fkey", type: "accounts"} =
               ctx.find.(accounts_orgs.associations, "accounts_orgs_account_id_fkey")

      assert %Endo.Association{name: "accounts_orgs_org_id_fkey", type: "orgs"} =
               ctx.find.(accounts_orgs.associations, "accounts_orgs_org_id_fkey")

      # Of course, individual tables might represent a many-to-one association. This likewise is
      # surfaced:
      assert Enum.count(repos.associations) == 1

      assert %Endo.Association{name: "repos_account_id_fkey", type: "accounts"} =
               ctx.find.(repos.associations, "repos_account_id_fkey")
    end

    test "lists tables and metadata for all tables with column" do
      # Only the `schema_migrations` table has a `version` column
      assert [%Endo.Table{name: "schema_migrations"}] =
               Endo.list_tables(Test.Postgres.Repo, with_column: "version")

      # Whereas all tables has an `inserted_at` column
      assert 5 ==
               Test.Postgres.Repo |> Endo.list_tables(with_column: "inserted_at") |> Enum.count()

      # `schema_migrations` does not have an `updated_at` however
      assert 4 ==
               Test.Postgres.Repo |> Endo.list_tables(with_column: "updated_at") |> Enum.count()
    end

    test "lists tables and metadata for all tables without column", ctx do
      # Only `schema_migrations` has a `version` column, so all other tables are returned
      assert tables = Endo.list_tables(Test.Postgres.Repo, without_column: "version")
      assert Enum.count(tables) == 4
      assert is_nil(ctx.find.(tables, "schema_migrations"))

      # Only `schema_migrations` lacks an `updated_at`
      assert tables = Endo.list_tables(Test.Postgres.Repo, without_column: "updated_at")
      assert Enum.count(tables) == 1
      refute is_nil(ctx.find.(tables, "schema_migrations"))
    end

    test "lists tables and metadata for all tables with and without columns", ctx do
      # Only `repos` has an `account_id` but no `org_id`
      assert tables =
               Endo.list_tables(Test.Postgres.Repo,
                 with_column: "account_id",
                 without_column: "org_id"
               )

      assert Enum.count(tables) == 1
      refute is_nil(ctx.find.(tables, "repos"))
    end

    test "lists tables and metadata for all tables with foreign key constraint", ctx do
      # Two tables are associated with `accounts`
      assert tables =
               Endo.list_tables(Test.Postgres.Repo, with_foreign_key_constraint: "accounts")

      assert Enum.count(tables) == 2
      refute is_nil(ctx.find.(tables, "repos"))
      refute is_nil(ctx.find.(tables, "accounts_orgs"))

      # Only one table is associated with `orgs`
      assert tables = Endo.list_tables(Test.Postgres.Repo, with_foreign_key_constraint: "orgs")
      assert Enum.count(tables) == 1
      refute is_nil(ctx.find.(tables, "accounts_orgs"))
    end

    test "lists tables and metadata for all tables without foreign key constraint", ctx do
      # As `accounts_orgs` and `repos` are associated with `accounts`; that means `accounts`, `orgs`,
      # and `schema_migrations` are _not_ associated with `accounts`
      assert tables =
               Endo.list_tables(Test.Postgres.Repo, without_foreign_key_constraint: "accounts")

      assert Enum.count(tables) == 3
      refute is_nil(ctx.find.(tables, "accounts"))
      refute is_nil(ctx.find.(tables, "orgs"))
      refute is_nil(ctx.find.(tables, "schema_migrations"))
    end

    test "lists tables and metadata for all tables with index", ctx do
      # Tables `accounts`, `orgs`, and `repos` have primary keys called `id`. These are
      # indexed by default.
      assert tables_1 = Endo.list_tables(Test.Postgres.Repo, with_index: "id")
      assert Enum.count(tables_1) == 3

      assert tables_2 = Endo.list_tables(Test.Postgres.Repo, with_column: "id")
      assert Enum.count(tables_2) == 3

      assert Enum.sort(tables_1) == Enum.sort(tables_2)

      # Only one table (`accounts`) in our migrations indexes `updated_at`
      assert tables = Endo.list_tables(Test.Postgres.Repo, with_index: "updated_at")
      refute is_nil(ctx.find.(tables, "accounts"))
    end

    test "lists tables and metadata for all tables with compound index" do
      # `accounts` has an index on `inserted_at`, and `updated_at`
      assert [%Endo.Table{name: "accounts"}] =
               Endo.list_tables(Test.Postgres.Repo,
                 table_name: "accounts",
                 with_index: "inserted_at"
               )

      assert [%Endo.Table{name: "accounts"}] =
               Endo.list_tables(Test.Postgres.Repo,
                 table_name: "accounts",
                 with_index: "updated_at"
               )

      # But it does _not_ have a compound index on both of those, these are two individual indexes
      assert [] =
               Endo.list_tables(Test.Postgres.Repo,
                 table_name: "accounts",
                 with_index: ["inserted_at", "updated_at"]
               )

      # `accounts_orgs` _does_ have a compound index on `account_id x org_id` however
      assert [%Endo.Table{name: "accounts_orgs"}] =
               Endo.list_tables(Test.Postgres.Repo, with_index: ["account_id", "org_id"])

      # Compound index lookup is order sentitive
      assert [] = Endo.list_tables(Test.Postgres.Repo, with_index: ["org_id", "account_id"])

      # And lookups of a single component will not work -- the full index must be given at all times
      assert [] = Endo.list_tables(Test.Postgres.Repo, with_index: "account_id")
    end

    test "lists tables and metadata for all tables without index", ctx do
      # Only `schema_migrations` and `accounts_orgs` do not define an `id` field, and thus by definition
      # these two tables have no indexes on said field
      assert tables = Endo.list_tables(Test.Postgres.Repo, without_index: "id")
      assert Enum.count(tables) == 2
      refute is_nil(ctx.find.(tables, "schema_migrations"))
      refute is_nil(ctx.find.(tables, "accounts_orgs"))

      # No tables defining an `id` field lack an index on `id`
      assert [] = Endo.list_tables(Test.Postgres.Repo, with_column: "id", without_index: "id")

      # Some tables define an `inserted_at` but don't index it however:
      assert tables =
               Endo.list_tables(Test.Postgres.Repo,
                 with_column: "inserted_at",
                 without_index: "inserted_at"
               )

      assert Enum.count(tables) == 4
      refute is_nil(ctx.find.(tables, "schema_migrations"))
      refute is_nil(ctx.find.(tables, "accounts_orgs"))
      refute is_nil(ctx.find.(tables, "orgs"))
      refute is_nil(ctx.find.(tables, "repos"))
    end

    test "lists tables and metadata for all tables without compound index", ctx do
      # Only `accounts_orgs` defines a compound index on `account_id` x `org_id`, thus all other
      # tables should be returned when this is excluded
      assert tables =
               Endo.list_tables(Test.Postgres.Repo, without_index: ["account_id", "org_id"])

      assert Enum.count(tables) == 4
      assert is_nil(ctx.find.(tables, "accounts_orgs"))
    end

    test "lists tables and metadata with given table name filters", ctx do
      assert [] = Endo.list_tables(Test.Postgres.Repo, table_name: "doesn't exist")

      assert [%Endo.Table{name: "accounts"}] =
               Endo.list_tables(Test.Postgres.Repo, table_name: "accounts")

      assert tables =
               Endo.list_tables(Test.Postgres.Repo, table_name: ["accounts", "random", "orgs"])

      assert is_nil(ctx.find.(tables, "random"))
      refute is_nil(ctx.find.(tables, "accounts"))
      refute is_nil(ctx.find.(tables, "orgs"))
    end
  end
end
