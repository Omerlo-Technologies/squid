defmodule Squid.Partial do
  @moduledoc ~S'''
  Partials are HTML snippets that squid can render according to their priority.
  Partials are useful to build navigation elements such as menus from your
  head app (the one that includes the squid router) by delegating the business
  logic to other apps.

  # Quickstart

      # in apps/tentacle_a/config/config.exs
      config :tentacle_a, :squid,
        partials: %{
          greetings_builder: {TentacleA.Greetings, priority: 1}
        }

      # in app/tentacle_a/lib/tentacle_a_web/greetings.ex
      defmodule TentacleA.Greetings do
        @behaviour Squid.Partial

        def render(assigns) do
          ~H"""
          <div>Hello <%= @user_name %> from tentacle A</div>
          """
        end
      end

      # in apps/tentacle_b/config/config.exs
      config :tentacle_b, :squid,
        partials: %{
          greetings_builder: {TentacleB.Greetings, priority: 2}
        }

      # in app/tentacle_b/lib/tentacle_b_web/greetings.ex
      defmodule TentacleB.Greetings do
        @behaviour Squid.Partial

        def render(assigns), do:
          ~H"""
          <div>Hello <%= @user_name %> from tentacle B</div>
          """
        end
      end

  Then in your page html

      <Squid.Partial.render partial={:greetings_builder} user_name="Squid's King" />

  This will generate the following html

      """
      <div>Hello Squid's King from tentacle B</div>
      <div>Hello Squid's King from tentacle A</div>
      """

  # Priorities

  The `priority` defines the order that your partials must be rendered.
  Partials with higher priority will be rendered first. A priority could be any
  `interger` or `float` values.

  '''

  @callback render(assigns :: map()) :: any()

  import Phoenix.Component

  def preload_partials() do
    Application.get_env(:squid, :tentacles)
    |> filter_applications()
    |> Enum.flat_map(fn otp_cfg ->
      otp_cfg
      |> Application.get_env(:squid)
      |> Keyword.get(:partials, [])
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(&sort_partial_modules/1)
    |> Enum.map(&to_partial_modules/1)
    |> then(&Application.put_env(:squid, :private_partials, &1))
  end

  def render(assigns) do
    partial = Map.fetch!(assigns, :partial)
    partial_modules = Application.get_env(:squid, :private_partials)[partial]
    assigns = %{assigns: assigns, partial_modules: partial_modules}

    ~H"""
    <%= for partial_part <- @partial_modules do %>
      <%= partial_part.render(@assigns) %>
    <% end %>
    """
  end

  def filter_applications(applications) do
    Enum.filter(applications, fn app ->
      Application.spec(app) || Application.get_env(app, :squid)[:force]
    end)
  end

  defp to_partial_modules({partial_name, partial_modules}) do
    partial_modules = Enum.map(partial_modules, &elem(&1, 0))
    {partial_name, partial_modules}
  end

  defp sort_partial_modules({partial_name, partial_modules}) do
    {partial_name,
     Enum.sort_by(partial_modules, fn {_module, opts} -> opts[:priority] end, :desc)}
  end
end
