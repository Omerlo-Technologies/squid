# Squid

Squid is a framework that helps you divide your application into multiple
small contexts and/or applications called `tentacles`.

Each `tentacle` defines its own logic (router, live view ...).

## Installation

This framework is in development and isn't fully ready for production yet.

```elixir
def deps do
  [
    {:squid,
      git: "https://github.com/drakkardigital/squid", tag: "0.3.0"},
  ]
end
```

## HeadRouter

```elixir
# config/config.exs

config :squid, tentacles: [:tentacle_a, :tentacle_b]


# apps/tentacle_a/config/config.exs

config :tentacle_a, :squid,
  router: Tentacle1Web.Router

# apps/tentacle_b/config/config.exs

config :tentacle_b, :squid,
  router: Tentacle2Web.Router

```

> Learn more about `SquidWeb.Router`.

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

> Learn more about squid routing system on the `SquidWeb.Router` module.


## Partials

One of the major feature of Squid is to construct partials using your
tentacles configurations. This is really usefull for building a menu or
any composed view.

```elixir
# in apps/tentacle_a/config/config.exs
config :tentacle_a, :squid,
  partials: %{
    greetings_builder: {TentacleA.Greetings, priority: 1}
  }

# in apps/tentacle_a/lib/tentacle_a_web/greetings.ex
defmodule TentacleA.Greetings do
  @behaviour SquidWeb.Partial

  def render_partial(assigns) do
    ~H"""
    <div>Hello <%= @user_name %> from tentacle A</div>
    """
  end
end
```

```elixir
# in apps/tentacle_b/config/config.exs
config :tentacle_b, :squid,
  partial: %{
    greetings_builder: {TentacleB.Greetings, priority: 2}
  }

# in apps/tentacle_b/lib/tentacle_b_web/greetings.ex
defmodule TentacleB.Greetings do
  @behaviour SquidWeb.Partial

  def render_partial(assigns), do:
    ~H"""
    <div>Hello <%= @user_name %> from tentacle B</div>
    """
  end
end
```

You could then generate this partial view using the following code

```elixir
<%= Partial.render(:greetings_builder, %{user_name: "Squid's King"}) %>
```

```html
<div>Hello Squid's King from tentacle B</div>
<div>Hello Squid's King from tentacle A</div>
```

> Learn more about squid partials system on the `SquidWeb.Partial` module.
