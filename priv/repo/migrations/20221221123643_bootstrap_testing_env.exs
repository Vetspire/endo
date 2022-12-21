defmodule Test.Postgres.Repo.Migrations.BootstrapTestingEnv do
  use Ecto.Migration

  def change do
    create_accounts()
    create_repos()
    create_orgs()
  end

  defp create_accounts do
    create table(:accounts) do
      add(:username, :string, null: false)
      add(:email, :string, null: false)

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
  end

  defp create_orgs do
    create table(:orgs) do
      add(:name, :string, null: false)

      timestamps()
    end

    create table(:accounts_orgs, primary_key: false) do
      add(:account_id, references(:accounts), null: false)
      add(:org_id, references(:orgs), null: false)

      timestamps()
    end

    create(unique_index(:accounts_orgs, [:account_id, :org_id]))
  end
end
