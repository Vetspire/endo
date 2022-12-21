if Mix.env() == :test do
  defmodule Test.Postgres.Repo do
    @moduledoc false
    use Ecto.Repo,
      otp_app: :endo,
      adapter: Ecto.Adapters.Postgres
  end
end
