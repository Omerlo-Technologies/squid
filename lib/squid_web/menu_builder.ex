defmodule SquidWeb.MenuBuilder do
  import Phoenix.LiveView.Helpers
  # TODO should allow custom templating

  def render(assigns) do
    ~H"""
    <%= for {_, tentacle_menu} <- SquidWeb.registered_menu_builders() do %>
      <%= for {type, item} <- tentacle_menu.build(assigns) do %>
        <%= render_menu_item(type, item) %>
      <% end %>
    <% end %>
    """
  end

  defp render_menu_item(:category, assigns) do
    ~H"""
     <div class="flex py-2 items-center">
       <div class="w-12 text-center">
         <i class={@icon}></i>
       </div>

       <%= @text %>
     </div>
    """
  end

  defp render_menu_item(:separator, assigns) do
    ~H"""
    <hr class="ml-12 my-1 border-gray-700">
    """
  end

  defp render_menu_item(:live_redirect, assigns) do
    ~H"""
    <%= live_redirect to: @path, class: "flex py-2 hover:bg-primary" do %>
      <div class="w-12 text-center">
        <i class={@icon}></i>
      </div>

      <%= @text %>
    <% end %>
    """
  end
end
