defmodule SquidWeb.RoutingTest do
  use ExUnit.Case, async: true
  use RouterHelper

  defmodule CustomController do
    use Phoenix.Controller
    def index(conn, _params), do: text(conn, "users index")
  end

  Application.put_env(:squid, :tentacles, [:tentacle_a, :tentacle_b, :tentacle_c])
  Application.put_env(:squid, :scopes, admin: [prefix: "/admin"])
  Application.put_env(:tentacle_a, :squid, router: SquidWeb.RoutingTest.RouterA)
  Application.put_env(:tentacle_b, :squid, router: SquidWeb.RoutingTest.RouterB)
  Application.put_env(:tentacle_c, :squid, router: SquidWeb.RoutingTest.RouterC)

  defmodule RouterA do
    use SquidWeb.Router
    alias CustomController, as: CustomControllerAliased

    squid_pipeline :tentacle_a_browser do
      plug(:add_header)
    end

    squid_scope "/tentacle-a" do
      pipe_through(:tentacle_a_browser)
      get("/index", CustomController, :index)
      get("/aliased", CustomControllerAliased, :index)
    end

    squid_scope "/tentacle-a", as: :admin do
      get("/index", CustomController, :index)
    end

    def add_header(conn, _opts) do
      Map.update!(conn, :private, &Map.put(&1, :pass_through, :tentacle_a_browser))
    end
  end

  defmodule RouterB do
    use SquidWeb.Router

    squid_pipeline :tentacle_b_browser do
      plug(:add_header)
    end

    squid_scope "/tentacle-b" do
      pipe_through(:tentacle_b_browser)
      get("/index", CustomController, :index)
    end

    def add_header(conn, _opts) do
      Map.update!(conn, :private, &Map.put(&1, :pass_through, :tentacle_b_browser))
    end
  end

  defmodule RouterC do
    use SquidWeb.Router

    squid_scope "/tentacle-c" do
      pipe_through(:tentacle_c_add_header)

      scope "/" do
        get("/index", CustomController, :index)
      end

      def tentacle_c_add_header(conn, _opts) do
        Map.update!(conn, :private, &Map.put(&1, :pass_through, :tentacle_c_browser))
      end
    end
  end

  SquidWeb.Router.create_dynamic_router([:tentacle_a, :tentacle_b, :tentacle_c])

  setup do
    %{router: SquidWeb.Router.dynamic_router()}
  end

  describe "routing" do
    test "get squid index path", %{router: router} do
      conn = call(router, :get, "/tentacle-a/index")
      assert conn.status == 200
      assert conn.resp_body == "users index"
    end

    test "get squid index path using aliased controller", %{router: router} do
      conn = call(router, :get, "/tentacle-a/aliased")
      assert conn.status == 200
      assert conn.resp_body == "users index"
    end

    test "get squid admin index path", %{router: router} do
      conn = call(router, :get, "/admin/tentacle-a/index")
      assert conn.status == 200
      assert conn.resp_body == "users index"
    end
  end

  describe "pipeline" do
    test "tentacle-a", %{router: router} do
      conn = call(router, :get, "/tentacle-a/index")
      assert conn.private[:pass_through] == :tentacle_a_browser
    end

    test "tentacle-b", %{router: router} do
      conn = call(router, :get, "/tentacle-b/index")
      assert conn.private[:pass_through] == :tentacle_b_browser
    end

    test "tentacle-c", %{router: router} do
      conn = call(router, :get, "/tentacle-c/index")
      assert conn.private[:pass_through] == :tentacle_c_browser
    end
  end
end
