defmodule Endo.Index do
  @moduledoc "Index metadata for a given table's indexes"

  alias Endo.Utils.ETS

  defmodule NotLoaded do
    @moduledoc false
    @type t :: %__MODULE__{}
    defstruct []
  end

  @type t :: %__MODULE__{}

  defstruct [
    :adapter,
    :name,
    :repo,
    :otp_app,
    :database,
    is_primary: false,
    is_unique: false,
    columns: []
  ]

  @doc """
  Tries to load a given `Endo.Column.t()`'s `indexes` field.

  Can take multiple inputs:
    - A single `Endo.Table.t()`
    - A list of `Endo.Table.t()`s
    - A single `Endo.Column.t()`
    - A list of `Endo.Column.t()`s

  Please note that given `Endo.Column.t()` structs, additional `Endo` lookups are necessary. Thus, for the best
  performance, it will be more optimal to pass in `Endo.Table.t()` structs if possible.

  Will raise an error if given a mixed list of `Endo.Column.t()`s and `Endo.Table.t()`s.
  """
  @spec load(Endo.Table.t() | Endo.Column.t()) :: Endo.Table.t() | Endo.Column.t()
  @spec load([Endo.Table.t() | Endo.Column.t()]) :: [Endo.Table.t() | Endo.Column.t()]
  def load([]) do
    []
  end

  def load([%Endo.Column{repo: repo} | _rest] = columns) do
    unless Enum.all?(columns, &is_struct(&1, Endo.Column)) do
      raise ArgumentError,
            "All entities in the list must be of type `Endo.Column.t()`. Got: #{inspect(columns)}"
    end

    tables =
      columns
      |> Enum.map(& &1.table_name)
      |> Enum.uniq()
      |> then(&Endo.list_tables(repo, table_name: &1))
      |> load()
      |> Map.new(&{&1.name, &1})

    Enum.map(columns, fn
      column when is_struct(column.indexes, NotLoaded) ->
        Enum.find(tables[column.table_name].columns, &(&1.name == column.name))

      column ->
        column
    end)
  end

  def load(%Endo.Column{table_name: table_name, repo: repo, indexes: %NotLoaded{}} = column) do
    %Endo.Table{columns: columns} =
      repo
      |> Endo.get_table(table_name)
      |> load()

    Enum.find(columns, &(&1.name == column.name))
  end

  def load(%Endo.Column{} = column) do
    column
  end

  def load([%Endo.Table{} | _rest] = tables) do
    unless Enum.all?(tables, &is_struct(&1, Endo.Table)) do
      raise ArgumentError,
            "All entities in list must be of type `Endo.Table.t()`. Got: #{inspect(tables)}"
    end

    tables
    |> Task.async_stream(&load/1, ordered: true, max_timeout: :timer.seconds(15))
    |> Enum.map(fn {:ok, resp} -> resp end)
  end

  def load(%Endo.Table{columns: columns, indexes: indexes} = table) do
    index_bag = ETS.new(:duplicate_bag)

    for index <- indexes, column <- index.columns do
      ETS.put(index_bag, column, index)
    end

    %Endo.Table{table | columns: Enum.map(columns, &do_load(&1, index_bag))}
  end

  defp do_load(%Endo.Column{indexes: %NotLoaded{}} = column, index_bag) do
    %Endo.Column{column | indexes: ETS.get(index_bag, column.name, [])}
  end

  # coveralls-ignore-start
  defp do_load(%Endo.Column{} = column, _index_bag) do
    column
  end
end
