defmodule Squid.RoutingTest do
  use ExUnit.Case, async: true
  use RouterHelper

  defmodule CustomController do
    use Phoenix.Controller
    def index(conn, _params), do: text(conn, "users index")
  end

  Application.put_env(:squid, :tentacles, [:tentacle_a, :tentacle_b, :tentacle_c])

  Application.put_env(:squid, :scopes,
    admin: [prefix: "/admin"],
    tentacle_prefixed: [prefix: "/{{tentacle_name}}/prefixed"]
  )

  Application.put_env(:tentacle_a, :squid, router: Squid.RoutingTest.RouterA)
  Application.put_env(:tentacle_b, :squid, router: Squid.RoutingTest.RouterB)
  Application.put_env(:tentacle_c, :squid, router: Squid.RoutingTest.RouterC)

  defmodule RouterA do
    use Squid.Router, otp_app: :tentacle_a

    squid_scope "/tentacle-a" do
      get("/index", CustomController, :index)
    end

    squid_scope "/tentacle-a", as: :admin do
      get("/index", CustomController, :index)
    end

    squid_scope "/", as: :tentacle_prefixed do
      get("/index", CustomController, :index)
    end
  end

  defmodule RouterB do
    use Squid.Router, otp_app: :tentacle_b

    squid_scope "/tentacle-b" do
      get("/index", CustomController, :index)
    end
  end

  defmodule TestEndpoint do
    use Plug.Builder

    plug(Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()
    )

    plug(Squid.Router)
  end

  describe "routing" do
    test "get squid index path for tentacle A" do
      conn =
        :get
        |> conn("/tentacle-a/index")
        |> TestEndpoint.call(TestEndpoint.init([]))

      assert conn.status == 200
      assert conn.resp_body == "users index"
    end

    test "get squid index path for tentacle B" do
      conn =
        :get
        |> conn("/tentacle-b/index")
        |> TestEndpoint.call(TestEndpoint.init([]))

      assert conn.status == 200
      assert conn.resp_body == "users index"
    end

    test "get squid index path using prefixed_tentacle" do
      conn =
        :get
        |> conn("/tentacle-a/prefixed/index")
        |> TestEndpoint.call(TestEndpoint.init([]))

      assert conn.status == 200
    end

    test "get squid admin index path" do
      conn =
        :get
        |> conn("/admin/tentacle-a/index")
        |> TestEndpoint.call(TestEndpoint.init([]))

      assert conn.status == 200
      assert conn.resp_body == "users index"
    end
  end
end
