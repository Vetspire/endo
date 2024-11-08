defmodule Test.Postgres.Repo.Migrations.BootstrapTestingEnv do
  use Ecto.Migration

  def change do
    create_accounts()
    create_repos()
    create_orgs()
    create_prefix_table()
  end

  def create_prefix_table do
    execute("CREATE SCHEMA debug")

    flush()

    create table(:events, prefix: "debug") do
      add(:type, :string, null: false)
      add(:data, :map, null: false)

      timestamps()
    end
  end

  defp create_accounts do
    create table(:accounts) do
      add(:username, :string, null: true)
      add(:email, :string, null: true)

      timestamps()
    end

    create(unique_index(:accounts, [:username]))
    create(unique_index(:accounts, [:email]))

    create(index(:accounts, [:inserted_at]))
    create(index(:accounts, [:updated_at]))
  end

  defp create_repos do
    create table(:repos) do
      add(:name, :string, null: false)
      add(:description, :string)

      add(:account_id, references(:accounts), null: false)

      timestamps()
    end

    create(unique_index(:repos, [:account_id, :name]))

    execute("""
      ALTER TABLE repos
      ADD COLUMN some_interval INTERVAL MINUTE TO SECOND;
    """)
  end

  defp create_orgs do
    create table(:orgs) do
      add(:name, :string, null: false)

      timestamps()
    end

    create table(:accounts_orgs, primary_key: false) do
      add(:account_id, references(:accounts), null: false)
      add(:org_id, references(:orgs), null: true)

      timestamps()
    end

    create(unique_index(:accounts_orgs, [:account_id, :org_id]))
  end
end
