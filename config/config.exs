import Config

config :endo, ecto_repos: [Test.Postgres.Repo], table_schema: "public"

config :endo, Test.Postgres.Repo,
  database: System.fetch_env!("POSTGRES_DB"),
  username: System.fetch_env!("POSTGRES_USER"),
  password: System.fetch_env!("POSTGRES_PASSWORD"),
  hostname: "localhost"
