defmodule Endo do
  @moduledoc false
  alias Endo.Adapters.Postgres

  @doc """
  Given an Ecto Repo, returns a list of all tables, columns, associations, and indexes.
  Takes an optional keyword list of filters which filter said tables down to given constraints.
  """
  @spec list_tables(repo :: module(), filters :: Keyword.t()) :: [Endo.Table.t()]
  def list_tables(repo, filters \\ []) do
    unless function_exported?(repo, :config, 0) do
      raise ArgumentError,
        message: "Expected a module that `use`-es `Ecto.Repo`, got: `#{inspect(repo)}`"
    end

    repo.config
    |> Keyword.get(:adapter)
    |> list_tables(repo, filters)
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
