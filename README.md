# Squid

Squid is a framwork to helper you deviding your application into multiple 
small context and/or applications called `tentacles`.

Each `tentacles` could define its own logic (router, live view ...).

## Installation

This framework is in development and not ready for production yet.

```elixir
def deps do
  [
    {:squid, 
      git: "https://github.com/drakkardigital/squid", branch: "master"},
  ]
end
```
