defmodule SquidWeb.Router do
  @moduledoc """
  Router helper to easily forward request to tentacle.

  ## Configurations

      # tentacle/config/config.exs

      config :squid,
        # head_router is optional (default: `SquidWeb.HeadRouter`)
        head_router: YourHead.Router,
        scopes:
          admin:
            prefix: "/admin"

  > The main purpose of the HeadRouter is to dispatch requests and
  > act as a proxy. We highly recommend to not use it in your code.
  > Instead you could use router that `use SquidWeb.Router`.

  You could also add specified configuration by env

      # tentacles/config/prod.exs
      config :squid,
        head_router: YourTentacle.Router,
        scopes:
          dev:
            disable: true

  ## Examples

      defmodule MyTentacleWeb.Router do
        use SquidWeb.Router

        squid_scope "/resources" do
          get "/action", MyTentacleWeb.MyResourceController, :index
        end

        squid_scope "/resources", as: :admin do
          get "/action", MyTentacleWeb.MyResourceAdminController, :index
        end

        squid_scope "/resources/dev", as: :dev do
          get "/action", MyTentacleWeb.MyResourceController, :debug
        end
      end

  With the configuration define in the previous chapter, this will generate
  followings path:

  - `/resources/action`
  - `/admin/resources/action`
  - `/resources/dev/action`

  Those path could be generate by your router's helper (as phoenix does)

      iex> MyTentacleWeb.Router.Helpers.custom_path(conn, :index)
      "/resources/action"

      iex> MyTentacleWeb.Router.Helpers.admin_custom_path(conn, :index)
      "/admin/resources/action"

  """

  def create_dynamic_router(tentacles) do
    router = dynamic_router()

    quote do
      use Phoenix.Router

      unquote(squid_scopes(tentacles))
    end
    |> then(&Module.create(router, &1, Macro.Env.location(__ENV__)))
  end

  defp squid_scopes(tentacles) do
    scopes = Application.get_env(:squid, :scopes)

    SquidWeb.registered_routers()
    |> Enum.filter(fn {tentacle, _} -> tentacle in tentacles end)
    |> Enum.flat_map(fn {tentacle, router} ->
      router.squid_scopes()
      |> Enum.map(fn {scope, block} -> {tentacle, scope, block} end)
    end)
    |> Enum.reject(fn {_tentacle, scope, _} -> scopes[scope][:disable] end)
    |> Enum.map(fn {tentacle, scope, do_block} ->
      prefix = scopes[scope][:prefix] || "/"

      quote do
        scope unquote(prefix), as: unquote(tentacle) do
          unquote(do_block)
        end
      end
    end)
  end

  def dynamic_router, do: Application.get_env(:squid, :head_router, SquidWeb.HeadRouter)

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
      use Phoenix.Router
      import SquidWeb.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router

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

  - `HeadWeb.Router.Helpers.tentacle_app_page_path/2` and
  - `MyTentacleWeb.Router.Helpers.page_path/2`

  You could also create routes under a scope such as `admin`.

    squid_scope "/my-tentacle-prefix", scope: :admin do
      get "/users", MyTentacleWeb.UserController, :index
    end

  ## Options

  - `scope` define the scope of the router such as `api`, `web`, `admin`. (default: `:default`)

  """
  defmacro squid_scope(path, opts \\ [], do_block) do
    scopes = Application.get_env(:squid, :scopes)
    curr_scope = Keyword.get(opts, :as, :default)
    prefix = scopes[curr_scope][:prefix] || "/"

    do_squid_internal_scope(path, opts, do_block)
    |> Macro.prewalk(&expand_alias(&1, __CALLER__))
    |> tap(&Module.put_attribute(__CALLER__.module, :squid_scopes, {curr_scope, &1}))
    |> then(&quote(do: scope(unquote(prefix), do: unquote(&1))))
  end

  defp expand_alias({:__aliases__, _, _} = alias, env),
    do: Macro.expand(alias, %{env | function: {:init, 1}})

  defp expand_alias(other, _env), do: other

  defp do_squid_internal_scope(path, opts, do_block) do
    quote do
      scope unquote(path), unquote(Macro.escape(opts)) do
        unquote(do_block)
      end
    end
  end
end
