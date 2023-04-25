defmodule Endo.Index do
  @moduledoc "Index metadata for a given table's indexes"

  alias Endo.Utils.ETS

  defmodule NotLoaded do
    @moduledoc false
    @type t :: %__MODULE__{}
    defstruct []
  end

  @type t :: %__MODULE__{}
  @default_load_timeout :timer.seconds(15)

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

  Takes an optional `Keyword.t()` of options:
    - `timeout` which is an integer representing the number of milliseconds before which loading should be aborted.
      This is only really a consideration for loading indexes across multiple tables and does not apply otherwise.
      Defaults to `:timer.seconds(15)`.

  """
  @spec load(Endo.Table.t() | Endo.Column.t(), opts :: Keyword.t()) ::
          Endo.Table.t() | Endo.Column.t()
  @spec load([Endo.Table.t() | Endo.Column.t()], opts :: Keyword.t()) :: [
          Endo.Table.t() | Endo.Column.t()
        ]
  def load([], _opts) do
    []
  end

  def load([%Endo.Column{repo: repo} | _rest] = columns, opts) do
    unless Enum.all?(columns, &is_struct(&1, Endo.Column)) do
      raise ArgumentError,
            "All entities in the list must be of type `Endo.Column.t()`. Got: #{inspect(columns)}"
    end

    tables =
      columns
      |> Enum.map(& &1.table_name)
      |> Enum.uniq()
      |> then(&Endo.list_tables(repo, table_name: &1))
      |> load(opts)
      |> Map.new(&{&1.name, &1})

    Enum.map(columns, fn
      column when is_struct(column.indexes, NotLoaded) ->
        Enum.find(tables[column.table_name].columns, &(&1.name == column.name))

      column ->
        column
    end)
  end

  def load(%Endo.Column{table_name: table, repo: repo, indexes: %NotLoaded{}} = column, opts) do
    %Endo.Table{columns: columns} =
      repo
      |> Endo.get_table(table)
      |> load(opts)

    Enum.find(columns, &(&1.name == column.name))
  end

  def load(%Endo.Column{} = column, _opts) do
    column
  end

  def load([%Endo.Table{} | _rest] = tables, opts) do
    unless Enum.all?(tables, &is_struct(&1, Endo.Table)) do
      raise ArgumentError,
            "All entities in list must be of type `Endo.Table.t()`. Got: #{inspect(tables)}"
    end

    timeout = Keyword.get(opts, :timeout, @default_load_timeout)

    tables
    |> Task.async_stream(&load(&1, opts), ordered: true, max_timeout: timeout)
    |> Enum.map(fn {:ok, resp} -> resp end)
  end

  def load(%Endo.Table{columns: columns, indexes: indexes} = table, _opts) do
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
