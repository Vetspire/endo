defmodule Endo.Application do
  @moduledoc false

  use Application

  # coveralls-ignore-start
  @impl Application
  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one, name: __MODULE__)
  end
end
