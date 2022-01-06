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
      SquidWeb.Router.import_routes

  """
  defmacro import_routes() do
    SquidWeb.registered_routers()
    |> Enum.map(&tentacle_routes/1)
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
    quote do
      import SquidWeb.Router
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  defp tentacle_routes({tentacle, router}), do: router.routes(tentacle)

  @doc """
  Helper to create a tentacle router.

  ## Example

    use SquidWeb.Router

    squid_scope "/my-tentacle-prefix" do
      get "/page", MyTentacleWeb.PageController, :index
    end

  This will register following helpers:

  - `CoreWeb.Router.Helpers.tentacle_app_page_path/2` and
  - `MyTentacleWeb.Router.Helpers.page_path/2`

  """
  defmacro squid_scope(path, opts \\ [], do_block) do
    quote do
      def routes(tentacle) do
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
