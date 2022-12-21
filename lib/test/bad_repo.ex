if Mix.env() == :test do
  defmodule Test.BadRepo do
    @moduledoc false

    @spec __adapter__ :: :test_adapter
    def __adapter__, do: :test_adapter
  end
end
