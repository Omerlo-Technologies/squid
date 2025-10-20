# Squid

A modular Phoenix framework for building applications with independent, composable sub-applications called **tentacles**.

Squid enables you to organize your Phoenix application into smaller, focused contexts that can be developed, tested, and deployed independently while sharing a common runtime. Each tentacle defines its own routes, controllers, and views, with the ability to configure different URL prefixes per deployment environment.

## Why Squid?

Phoenix's `forward/4` macro doesn't work properly with LiveView because it loses important routing metadata that LiveView depends on for features like live navigation, URL generation, and route helpers. This makes it difficult to build modular Phoenix applications with multiple independent routers, especially in umbrella apps or when organizing code by domain.

**Squid solves this problem** by directly calling each router's `__match_route__/3` function instead of using `forward`, preserving all the metadata that LiveView needs. This allows you to:

- Use multiple independent routers with full LiveView support
- Forward requests between routers without breaking live navigation
- Build truly modular Phoenix applications with proper encapsulation
- Organize umbrella apps where each sub-app has its own router and LiveViews

## Features

- **Modular Routing**: Each tentacle has its own router with configurable prefixes
- **Dynamic Scopes**: Deploy the same tentacle code under different URL structures
- **Composable Partials**: Build UI components by aggregating views from multiple tentacles
- **Flexible Architecture**: Support for multi-tenant, microservices-style, or domain-driven designs
- **Full LiveView Support**: Unlike `forward/4`, Squid preserves all routing metadata for LiveView

## Installation

Add `squid` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:squid, "~> 0.2.0"}
  ]
end
```

## Quick Start

### 1. Configure Your Tentacles

Register all tentacles in your main application config:

```elixir
# config/config.exs
config :squid,
  tentacles: [:shop, :admin, :billing]
```

### 2. Create a Tentacle Router

Each tentacle defines its own router using `Squid.Router`:

```elixir
# lib/shop/router.ex
defmodule Shop.Router do
  use Squid.Router, otp_app: :shop

  squid_scope "/products" do
    get "/", Shop.ProductController, :index
    get "/:id", Shop.ProductController, :show
  end
end
```

Register the router in the tentacle's config:

```elixir
# In shop's config
config :shop, :squid,
  router: Shop.Router
```

### 3. Add Squid Router to Your Endpoint

Replace the standard Phoenix router with `Squid.Router` in your endpoint:

```elixir
# lib/my_app_web/endpoint.ex
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # Instead of `plug MyAppWeb.Router`
  plug Squid.Router
end
```

## Configurable Scopes

Define scopes to deploy tentacles with different URL prefixes:

```elixir
# config/config.exs
config :squid,
  scopes: [
    default: [prefix: "/"],
    admin: [prefix: "/admin"],
    api: [prefix: "/api/v1"],
    tenant: [prefix: "/{{tentacle_name}}"]
  ]
```

Use scopes in your tentacle routers:

```elixir
defmodule Shop.Router do
  use Squid.Router, otp_app: :shop

  # Public routes at /products
  squid_scope "/products" do
    get "/", Shop.ProductController, :index
  end

  # Admin routes at /admin/products
  squid_scope "/products", as: :admin do
    post "/", Shop.AdminController, :create
    delete "/:id", Shop.AdminController, :delete
  end

  # API routes at /api/v1/products
  squid_scope "/products", as: :api do
    get "/", Shop.API.ProductController, :index
  end
end
```

### Dynamic Tentacle Names

Use the `{{tentacle_name}}` placeholder to create tenant-specific routes:

```elixir
config :squid,
  scopes: [
    tenant: [prefix: "/{{tentacle_name}}"]
  ]

# In :billing_system tentacle with `as: :tenant`
# Routes will be prefixed with /billing-system
```

The tentacle name is automatically converted from `snake_case` to `kebab-case`.

## Partials System

Build composable UI components by aggregating partials from multiple tentacles.

### Define Partials in Tentacles

```elixir
# apps/shop/config/config.exs
config :shop, :squid,
  router: Shop.Router,
  partials: %{
    navigation: {Shop.Navigation, priority: 1}
  }

# apps/shop/lib/shop/navigation.ex
defmodule Shop.Navigation do
  @behaviour Squid.Partial

  def render(assigns) do
    ~H"""
    <a href="/products">Products</a>
    """
  end
end
```

```elixir
# apps/admin/config/config.exs
config :admin, :squid,
  router: Admin.Router,
  partials: %{
    navigation: {Admin.Navigation, priority: 2}
  }

# apps/admin/lib/admin/navigation.ex
defmodule Admin.Navigation do
  @behaviour Squid.Partial

  def render(assigns) do
    ~H"""
    <a href="/admin/users">Admin</a>
    """
  end
end
```

### Render Aggregated Partials

```elixir
<Squid.Partial.render partial={:navigation} current_user={@current_user} />
```

Partials are rendered in priority order (highest first), allowing you to control the composition of your UI.

## Documentation

For detailed documentation, see:

- `Squid.Router` - Architecture overview and plug configuration
- `Squid.Router.Scope` - Complete guide to scopes and `squid_scope/3`
- `Squid.Partial` - Composable UI partials system

Or generate documentation locally:

```bash
mix docs
```

## Use Cases

### Multi-Tenant Applications

Deploy the same tentacle code with different URL prefixes per tenant:

```elixir
config :squid,
  scopes: [
    tenant_a: [prefix: "/tenant-a"],
    tenant_b: [prefix: "/tenant-b"]
  ]
```

### Microservices-Style Monolith

Organize your application into independent services while keeping them in a single runtime:

```elixir
config :squid,
  tentacles: [:auth, :payments, :notifications, :analytics]
```

### Domain-Driven Design

Structure your application by business domains, each with its own router and views:

```elixir
config :squid,
  tentacles: [:orders, :inventory, :shipping, :billing]
```

## Development Status

Squid is currently in active development. While functional, the API may change before reaching v1.0. Feedback and contributions are welcome!

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.

## Links

- [GitHub Repository](https://github.com/Omerlo-Technologies/squid)
- [Hex Package](https://hex.pm/packages/squid)
- [Documentation](https://hexdocs.pm/squid)
