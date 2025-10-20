defmodule Squid.Router do
  @moduledoc """
  A routing system for modular Phoenix applications organized as "tentacles".

  `Squid.Router` extends `Phoenix.Router` to support modular application architectures
  where multiple sub-applications (tentacles) can define their own routes independently,
  with the ability to deploy them under configurable prefixes.

  This module serves two purposes:

  1. **As a macro (`use Squid.Router`)**: Provides the `squid_scope/3` macro for defining
     routes in tentacle routers
  2. **As a Plug**: Aggregates and dispatches incoming requests to all registered tentacle routers

  ## Architecture Overview

  In a Squid-based application:

  - Each **tentacle** (sub-application) defines its own router using `use Squid.Router`
  - Each tentacle router uses `squid_scope/3` to define routes that adapt to configuration
  - The main application adds `plug Squid.Router` to its endpoint
  - At runtime, the plug dispatches requests to the appropriate tentacle router

  ## Setting Up a Tentacle Router

      defmodule MyTentacle.Router do
        use Squid.Router, otp_app: :my_tentacle

        squid_scope "/users" do
          get "/", MyTentacle.UserController, :index
        end

        squid_scope "/users", as: :admin do
          delete "/:id", MyTentacle.UserController, :delete
        end
      end

  For detailed documentation on `squid_scope/3` and scope configuration, see `Squid.Router.Scope`.

  ## Registering Tentacles

  Register all tentacles in your main application configuration:

      # config/config.exs
      config :squid,
        tentacles: [:tentacle_a, :tentacle_b, :my_tentacle]

  Each tentacle must also register its router:

      # In my_tentacle's config
      config :my_tentacle, :squid,
        router: MyTentacle.Router

  ## Using as a Plug

  Add `Squid.Router` to your Phoenix endpoint to enable request dispatching:

      defmodule MyAppWeb.Endpoint do
        use Phoenix.Endpoint, otp_app: :my_app

        # Instead of `plug MyAppWeb.Router`
        plug Squid.Router
      end

  **Important**: Use `plug Squid.Router` instead of `plug MyAppWeb.Router`. The Squid router
  will aggregate and dispatch to all tentacle routers, including your main application router
  if it's registered as a tentacle.

  The plug will:
  1. Load all registered tentacle routers at initialization
  2. For each request, iterate through routers until one matches
  3. Raise `Squid.Router.NoRouteError` if no route matches

  ## See Also

  - `Squid.Router.Scope` - Complete guide to `squid_scope/3` and scope configuration
  - `Squid.Router.NoRouteError` - Exception raised when no route matches
  """

  @doc """
  `Squid.Router` does the exact same thing as `Phoenix.Router` but add the support of `squid_scope`.

  > Learn more in `Squid.Router.Scope`

  """
  defmacro __using__(opts) do
    otp_app =
      opts[:otp_app] || raise ":otp_app option is required by squid router (#{__CALLER__.module})"

    Module.register_attribute(__CALLER__.module, :otp_app, persist: true)
    Module.put_attribute(__CALLER__.module, :otp_app, otp_app)

    quote do
      use Phoenix.Router
      import Squid.Router
      import Squid.Router.Scope

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  defmodule NoRouteError do
    @moduledoc """
    Exception raised when no route is found.
    """
    defexception plug_status: 404, message: "no route found", conn: nil, routers: []

    def exception(opts) do
      conn = Keyword.fetch!(opts, :conn)
      routers = Keyword.fetch!(opts, :routers)
      path = "/" <> Enum.join(conn.path_info, "/")

      %NoRouteError{
        message: "no route found for #{conn.method} #{path}",
        conn: conn,
        routers: routers
      }
    end
  end

  @behaviour Plug

  @impl Plug
  def init(_opts) do
    Application.get_env(:squid, :tentacles)
    |> Enum.map(fn tentacle_app ->
      Application.get_env(tentacle_app, :squid)
      |> Access.get(:router)
    end)
    |> Enum.reject(&is_nil/1)
  end

  @impl Plug
  def call(conn, routers) do
    %{method: method, path_info: path_info, host: host} = conn = conn
    decoded = Enum.map(path_info, &URI.decode/1)

    Enum.reduce_while(routers, :error, fn router, _acc ->
      case router.__match_route__(decoded, method, host) do
        {metadata, prepare, pipeline, plug_opts} ->
          {:halt, Phoenix.Router.__call__(conn, metadata, prepare, pipeline, plug_opts)}

        :error ->
          {:cont, :error}
      end
    end)
    |> case do
      %Plug.Conn{} = conn -> conn
      :error -> raise NoRouteError, conn: conn, routers: routers
    end
  end
end
