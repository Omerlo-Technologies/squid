defmodule SquidWeb.RoutingTest do
  use ExUnit.Case, async: true
  use RouterHelper

  defmodule CustomController do
    use Phoenix.Controller
    def index(conn, _params), do: text(conn, "users index")
  end

  defmodule Router do
    use SquidWeb.Router

    squid_scope "/squid-scope" do
      get("/index", CustomController, :index)
    end

    squid_scope "/admin-scope", scope: :admin do
      get("/index", CustomController, :index)
    end
  end

  Application.put_env(:squid, :tentacles, [:test])
  Application.put_env(:test, :squid, router: Router)

  defmodule PhoenixRouter do
    use Phoenix.Router
    require SquidWeb.Router

    scope "/main-router" do
      SquidWeb.Router.import_routes()
    end

    scope "/admin" do
      SquidWeb.Router.import_routes(:admin)
    end

    SquidWeb.Router.import_routes(:unknow_scope)
  end

  describe "routing" do
    test "get squid index path" do
      conn = call(PhoenixRouter, :get, "/main-router/squid-scope/index")
      assert conn.status == 200
      assert conn.resp_body == "users index"
    end

    test "get squid admin index path" do
      conn = call(PhoenixRouter, :get, "/admin/admin-scope/index")
      assert conn.status == 200
      assert conn.resp_body == "users index"
    end
  end

  describe "squid scopes" do
    test "Should contains admin and default" do
      assert :default in Router.squid_scopes()
      assert :admin in Router.squid_scopes()
    end
  end
end
