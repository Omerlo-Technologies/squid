defmodule SquidWeb.Router do
  @moduledoc """
  Router helper to easily forward request to tentacle.

  This module is use by your tentacle to register themself
  into `Squid` but also by your router to automatically add
  tentacles routing rules.

  ## Example

      # tentacle/config/config.exs

      config :your_tentacle, :squid,
        router: YourTentacle.Router

  """

  @doc """
  Use `SquidWeb.Router` in your main router to automatically add forward
  rules to your tentacle.

  ## Example

      require SquidWeb.Router
      SquidWeb.Router.import_routes()

      # or with a scope

      require SquidWeb.Router
      SquidWeb.Router.import_routes(:admin)

  """
  defmacro import_routes(scope \\ :default) do
    SquidWeb.registered_routers()
    |> Enum.map(&tentacle_routes(&1, scope))
  end

  defp tentacle_routes({tentacle, router}, scope) do
    opts = [tentacle: tentacle, scope: scope]

    quote do
      use unquote(router), unquote(Macro.escape(opts))
    end
  end

  @doc """
  Helper to create a tentacle router.

  ## Example

    use SquidWeb.Router

    squid_scope "/my-tentacle-prefix" do
      get "/page", MyTentacleWeb.PageController, :index
    end

  > See `squid_scope/3` for more informations.

  """
  defmacro __using__(_) do
    Module.register_attribute(__CALLER__.module, :squid_scopes, accumulate: true)

    quote do
      import SquidWeb.Router
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router

      defmacro __using__(opts \\ []) do
        tentacle = Keyword.fetch!(opts, :tentacle)
        scope = Keyword.get(opts, :scope, :default)

        if scope in @squid_scopes do
          require Logger
          Logger.debug("SquidRouter - Import scope \"#{scope}\" for tentacle \"#{tentacle}\".")
          squid_routes(tentacle, scope)
        end
      end

      @before_compile SquidWeb.Router
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def squid_scopes, do: @squid_scopes
    end
  end

  @doc """
  Helper to create a tentacle router.

  ## Examples

    use SquidWeb.Router

    squid_scope "/my-tentacle-prefix" do
      get "/page", MyTentacleWeb.PageController, :index
    end

  This will register following helpers:

  - `CoreWeb.Router.Helpers.tentacle_app_page_path/2` and
  - `MyTentacleWeb.Router.Helpers.page_path/2`

  You could also create routes under a scope such as `admin`.

    squid_scope "/my-tentacle-prefix", scope: :admin do
      get "/users", MyTentacleWeb.UserController, :index
    end

  You could then import those routes with `SquidWeb.Router.import(scope)`.

  > More information on `SquidWeb.Router.import_routes/1`

  ## Options

  - `scope` define the scope of the router such as `api`, `web`, `admin`. (default: `:default`)

  """
  defmacro squid_scope(path, opts \\ [], do_block) do
    scope = Keyword.get(opts, :scope, :default)

    Module.put_attribute(__CALLER__.module, :squid_scopes, scope)

    quote do
      def squid_routes(tentacle, unquote(scope)) do
        routes = unquote(Macro.escape(do_squid_internal_scope(path, opts, do_block)))

        quote do
          scope "/", as: unquote(tentacle) do
            unquote(routes)
          end
        end
      end

      unquote(do_squid_internal_scope(path, opts, do_block))
    end
  end

  defp do_squid_internal_scope(path, opts, do_block) do
    quote do
      scope unquote(path), unquote(Macro.escape(opts)) do
        unquote(do_block)
      end
    end
  end
end
