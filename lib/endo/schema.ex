defmodule Endo.Schema do
  @moduledoc "Utility module for discovering Ecto Schema implementations for a given Endo Table"

  defmodule NotLoaded do
    @moduledoc false

    @type t :: %__MODULE__{}
    defstruct [:table, :otp_app]
  end

  @spec load([Endo.Table.t()]) :: [Endo.Table.t()]
  @spec load(Endo.Table.t()) :: Endo.Table.t()

  @doc """
  Given a list of Endo Tables, tries to load their schemas in their corresponding OTP App.

  All Endo Table structs contain metadata about which OTP app a given Repo belongs to. This information is used
  to load all Elixir modules that `use Ecto.Schema`.

  With this list, we match up any schemas to tables that exist; though it is important to note that not all
  Endo Tables will necessarily have a corresponding Ecto Schema module defined for it.

  In this case, the `schemas` key of an Endo Table will be an empty list.

  It is also possible for multiple Ecto Schemas to exist for a single underlying database tables, thus, any discovered
  results will be accumulated and returned as a list of modules per Endo Table.
  """
  def load([%Endo.Table{} | _rest] = endo_tables) do
    unless Enum.all?(endo_tables, &is_struct(&1, Endo.Table)) do
      endo_tables = inspect(endo_tables)

      raise ArgumentError,
        message: "All entities in list must be of type `Endo.Table.t()`. Got: #{endo_tables}"
    end

    {unloaded_endo_tables, loaded_endo_tables} =
      Enum.split_with(endo_tables, &is_struct(&1.schemas, NotLoaded))

    loaded_endo_tables ++
      (unloaded_endo_tables
       |> Enum.group_by(& &1.schemas.otp_app)
       |> Enum.flat_map(fn {otp_app, endo_tables} ->
         app_schemas = app_schemas(otp_app)
         Enum.map(endo_tables, &do_load(&1, app_schemas))
       end))
  end

  def load(%Endo.Table{schemas: %NotLoaded{otp_app: otp_app}} = endo_table) do
    do_load(endo_table, app_schemas(otp_app))
  end

  defp do_load(%Endo.Table{schemas: %NotLoaded{table: table}} = endo_table, app_schemas) do
    %Endo.Table{endo_table | schemas: Map.get(app_schemas, table, [])}
  end

  defp app_schemas(otp_app) when is_atom(otp_app) do
    {:ok, modules} = :application.get_key(otp_app, :modules)

    modules
    |> Enum.filter(&function_exported?(&1, :__schema__, 1))
    |> Enum.group_by(& &1.__schema__(:source))
  end
end
