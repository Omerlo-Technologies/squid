defmodule SquidWeb.PartialTest do
  use ExUnit.Case

  alias SquidWeb.Partial

  import Phoenix.LiveView.Helpers

  defmodule TentacleA.Greetings do
    @behaviour SquidWeb.Partial

    def render(assigns) do
      ~H"""
      Hello <%= @user_name %> from tentacle A
      """
    end
  end

  defmodule TentacleB.Greetings do
    @behaviour SquidWeb.Partial

    def render(assigns) do
      ~H"""
      Hello <%= @user_name %> from tentacle B
      """
    end
  end

  setup do
    partial_a = TentacleA.Greetings
    partial_b = TentacleB.Greetings

    put_partials_cfg(:tentacle_a, :greetings_builder, {partial_a, [priority: 1]})
    put_partials_cfg(:tentacle_b, :greetings_builder, {partial_b, [priority: 2]})
    Application.put_env(:squid, :tentacles, [:tentacle_a, :tentacle_b])

    Partial.preload_partials()

    %{partial_a: partial_a, partial_b: partial_b}
  end

  test "Partial cfg are preload by partial", %{partial_a: pa, partial_b: pb} do
    partials = Application.get_env(:squid, :private_partials)[:greetings_builder]

    assert pa in partials
    assert pb in partials
  end

  test "Partial cfg sorted by priority", %{partial_a: pa, partial_b: pb} do
    partials = Application.get_env(:squid, :private_partials)[:greetings_builder]

    assert partials == [pb, pa]
  end

  test "Rendering a partial" do
    html = Partial.render(%{partial: :greetings_builder, user_name: "Squid's King"}) |> h2s()

    assert html == """

             Hello Squid&#39;s King from tentacle B


             Hello Squid&#39;s King from tentacle A

           """
  end

  defp h2s(template) do
    template
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp put_partials_cfg(otp_app, partial_name, cfg) do
    Application.get_env(otp_app, :squid, [])
    |> Keyword.put(:partials, %{partial_name => cfg})
    |> then(&Application.put_env(otp_app, :squid, &1))
  end
end
