if Mix.env() == :test do
  defmodule Test.Postgres.Org do
    @moduledoc false

    use Ecto.Schema

    schema "orgs" do
    end
  end
end
