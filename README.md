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
      git: "https://github.com/drakkardigital/squid", branch: "main"},
  ]
end
```
