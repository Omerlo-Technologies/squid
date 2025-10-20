defmodule Squid.Router.Scope do
  @moduledoc """
  Provides the `squid_scope/3` macro for defining routes with configurable prefixes.

  This module enables tentacle routers to define routes that automatically adapt to
  different deployment configurations through named scopes. Each scope can have its
  own prefix, allowing the same tentacle code to be deployed with different URL structures.

  ## How squid_scope Works

  The `squid_scope/3` macro wraps Phoenix's `scope/3` by:

  1. Looking up the scope configuration from `:squid, :scopes`
  2. Retrieving the prefix for the requested scope (`:as` option, defaults to `:default`)
  3. Replacing `{{tentacle_name}}` placeholders with the tentacle's OTP app name (kebab-case)
  4. Joining the scope prefix with the provided path
  5. Generating a standard Phoenix `scope/3` with the computed path

  ## Scope Configuration

  Scopes are configured globally in your application config:

      # config/config.exs
      config :squid,
        scopes: [
          default: [prefix: "/"],
          admin: [prefix: "/admin"],
          api: [prefix: "/api/v1"],
          tenant: [prefix: "/{{tentacle_name}}"]
        ]

  ### Dynamic Tentacle Names

  Use `{{tentacle_name}}` to include the tentacle's OTP app name in the prefix.
  The name is automatically converted from `snake_case` to `kebab-case`:

      # With scope config: api: [prefix: "/{{tentacle_name}}/api"]
      # In :billing_system tentacle
      squid_scope "/invoices", as: :api do
        get "/", InvoiceController, :index
      end
      # Generates: GET /billing-system/api/invoices

  ## Usage Examples

  ### Basic Usage (default scope)

      squid_scope "/users" do
        get "/", UserController, :index
        get "/:id", UserController, :show
      end

  With `default: [prefix: "/"]`, this generates `/users` and `/users/:id`.

  ### Named Scopes

      # Public API
      squid_scope "/users", as: :api do
        get "/", API.UserController, :index
      end

      # Admin routes
      squid_scope "/users", as: :admin do
        delete "/:id", AdminUserController, :delete
      end

  With the config above:
  - `GET /api/v1/users` (api scope)
  - `DELETE /admin/users/:id` (admin scope)

  ### With Phoenix Scope Options

  All Phoenix `scope/3` options are supported:

      squid_scope "/api", as: :api, alias: MyTentacle.API, host: "api." do
        get "/status", StatusController, :show
      end

  ## Path Construction

  The final path is constructed as:

      scope_prefix = config[:squid][:scopes][scope_name][:prefix]
      scope_prefix = String.replace(scope_prefix, "{{tentacle_name}}", tentacle_name_kebab)
      final_path = Path.join(scope_prefix, provided_path)

  If the scope configuration is missing or has no prefix, "/" is used as the default.

  ## Complete Example

      # config/config.exs
      config :squid,
        scopes: [
          default: [prefix: "/"],
          admin: [prefix: "/admin"],
          api: [prefix: "/{{tentacle_name}}/api"]
        ]

      # lib/shop/router.ex (in :shop tentacle)
      defmodule Shop.Router do
        use Squid.Router, otp_app: :shop

        squid_scope "/products" do
          get "/", ProductController, :index                    # GET /products
        end

        squid_scope "/products", as: :admin do
          post "/", AdminProductController, :create             # POST /admin/products
        end

        squid_scope "/products", as: :api do
          get "/", API.ProductController, :index                # GET /shop/api/products
        end
      end
  """

  @doc """
  Defines a scope with configurable prefix based on application configuration.

  This macro works similarly to Phoenix's `scope/3` but applies a prefix based on the
  scope configuration (`:squid, :scopes`) before creating the actual Phoenix scope.

  ## Examples

      use Squid.Router, otp_app: :my_tentacle

      squid_scope "/resources" do
        get "/page", MyTentacle.PageController, :index
      end

  You can specify a named scope using the `:as` option:

      squid_scope "/users", as: :admin do
        get "/", MyTentacle.UserController, :index
      end

  ## Options

  - `:as` - The named scope to use from config (defaults to `:default`). This determines
    which prefix configuration will be applied.
  - All other options are passed through to Phoenix's `scope/3` macro (`:alias`, `:host`, etc.)

  """
  defmacro squid_scope(path, opts \\ [], do_block) do
    scopes = Application.get_env(:squid, :scopes)
    curr_scope = Keyword.get(opts, :as, :default)

    otp_app = Module.get_attribute(__CALLER__.module, :otp_app)
    prefix = build_tentacle_prefix(otp_app, scopes[curr_scope][:prefix])

    path = Path.join(prefix, path)

    quote do
      scope unquote(path), unquote(Macro.escape(opts)) do
        unquote(do_block)
      end
    end
  end

  defp build_tentacle_prefix(_tentacle, nil = _prefix), do: "/"

  defp build_tentacle_prefix(tentacle, prefix) do
    tentacle_name = String.replace("#{tentacle}", "_", "-")
    String.replace(prefix, "{{tentacle_name}}", tentacle_name)
  end
end
