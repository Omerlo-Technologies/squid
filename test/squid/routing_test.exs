defmodule SquidWeb.RoutingTest do
  use ExUnit.Case, async: true
  use RouterHelper

  defmodule CustomController do
    use Phoenix.Controller
    def index(conn, _params), do: text(conn, "users index")
  end

  Application.put_env(:squid, :tentacles, [:test])
  Application.put_env(:squid, :scopes, admin: [prefix: "/admin"])
  Application.put_env(:test, :squid, router: SquidWeb.RoutingTest.Router)

  defmodule Router do
    use SquidWeb.Router
    alias CustomController, as: CustomControllerAliased

    squid_scope "/squid-scope" do
      get("/index", CustomController, :index)
      get("/aliased", CustomControllerAliased, :index)
    end

    squid_scope "/admin-scope", as: :admin do
      get("/index", CustomController, :index)
    end
  end

  SquidWeb.Router.create_dynamic_router([:test])

  describe "routing" do
    setup do
      %{router: SquidWeb.Router.dynamic_router()}
    end

    test "get squid index path", %{router: router} do
      conn = call(router, :get, "/squid-scope/index")
      assert conn.status == 200
      assert conn.resp_body == "users index"
    end

    test "get squid index path using aliased controller", %{router: router} do
      conn = call(router, :get, "/squid-scope/aliased")
      assert conn.status == 200
      assert conn.resp_body == "users index"
    end

    test "get squid admin index path", %{router: router} do
      conn = call(router, :get, "/admin/admin-scope/index")
      assert conn.status == 200
      assert conn.resp_body == "users index"
    end
  end
end
