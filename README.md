# Squid

Squid is a framework that helps you divide your application into multiple
small contexts and/or applications called `tentacles`.

Each `tentacle` defines its own logic (router, live view ...).

## Installation

This framework is in development and not ready for production yet.

```elixir
def deps do
  [
    {:squid,
      git: "https://github.com/drakkardigital/squid", tag: "0.2.0"},
  ]
end
```

## Quickstart


### Configures the head router

```elixir
# config/config.exs

config :squid, tentacles: [:tentacle_1, :tentacle_2]


# apps/tentacle_1/config/config.exs

config :tentacle_1,
  squid:
	  router: Tentacle1Web.Router


# apps/tentacle_2/config/config.exs

config :tentacle_2,
  squid:
	  router: Tentacle2Web.Router

```

Then create the dynamic router with the following code.

```elixir
defmodule YourHeadApp do
  use Application

	def start(_type, args) do
	  # The next line is REALLY important
    SquidWeb.create_dynamic_router()

    children = []
    Supervisor.start_link(children, strategy: :one_for_one)
	end
end
```

Learn more about squid routing system on the `SquidWeb.Router` module.

