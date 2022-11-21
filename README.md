# Endo

<!--
TODO: fixme
[![hex.pm](https://img.shields.io/hexpm/v/endo.svg)](https://hex.pm/packages/endo)
[![hexdocs.pm](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/endo/)
[![hex.pm](https://img.shields.io/hexpm/dt/endo.svg)](https://hex.pm/packages/endo)
[![hex.pm](https://img.shields.io/hexpm/l/endo.svg)](https://hex.pm/packages/endo)
-->

Endo is a library containing database schema reflection APIs for your applications, as
well as implementations of queryable schemas to facilitate custom database reflection
via Ecto.

See the [official documentation for Endo](https://hexdocs.pm/endo/).

## Installation

This package can be installed by adding `endo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:endo, "~> 0.1.0"}
  ]
end
```

## Contributing

We enforce 100% code coverage and quite a strict linting setup for Endo.

Please ensure that commits pass CI. You should be able to run both `mix test` and
`mix lint` locally.

See the `mix.exs` to see the breakdown of what these commands do.
