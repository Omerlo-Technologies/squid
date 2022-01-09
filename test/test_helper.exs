Code.require_file("support/router_helper.exs", __DIR__)

# Used whenever a router fails. We default to simply
# rendering a short string.
defmodule Phoenix.ErrorView do
  def render("404.json", %{kind: kind, reason: _reason, stack: _stack, conn: conn}) do
    %{error: "Got 404 from #{kind} with #{conn.method}"}
  end

  def render(template, %{conn: conn}) do
    unless conn.private.phoenix_endpoint do
      raise "no endpoint in error view"
    end
    "#{template} from Phoenix.ErrorView"
  end
end

ExUnit.start()
