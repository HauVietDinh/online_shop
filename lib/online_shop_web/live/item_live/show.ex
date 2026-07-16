defmodule OnlineShopWeb.ItemLive.Show do
  use OnlineShopWeb, :live_view

  alias OnlineShop.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Item {@item.id}
        <:subtitle>This is a item record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/items"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/items/#{@item}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit item
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Item code">{@item.item_code}</:item>
        <:item title="Name">{@item.name}</:item>
        <:item title="Category">{@item.category}</:item>
        <:item title="Price cents">{@item.price_cents}</:item>
        <:item title="Amount">{@item.amount}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Catalog.subscribe_items(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Item")
     |> assign(:item, Catalog.get_item!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %OnlineShop.Catalog.Item{id: id} = item},
        %{assigns: %{item: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :item, item)}
  end

  def handle_info(
        {:deleted, %OnlineShop.Catalog.Item{id: id}},
        %{assigns: %{item: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current item was deleted.")
     |> push_navigate(to: ~p"/items")}
  end

  def handle_info({type, %OnlineShop.Catalog.Item{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
