defmodule OnlineShopWeb.ItemLive.Index do
  use OnlineShopWeb, :live_view

  alias OnlineShop.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Items
        <:actions>
          <.button variant="primary" navigate={~p"/items/new"}>
            <.icon name="hero-plus" /> New Item
          </.button>
        </:actions>
      </.header>

      <.table
        id="items"
        rows={@streams.items}
        row_click={fn {_id, item} -> JS.navigate(~p"/items/#{item}") end}
      >
        <:col :let={{_id, item}} label="Item code">{item.item_code}</:col>
        <:col :let={{_id, item}} label="Name">{item.name}</:col>
        <:col :let={{_id, item}} label="Category">{item.category}</:col>
        <:col :let={{_id, item}} label="Price cents">{item.price_cents}</:col>
        <:col :let={{_id, item}} label="Amount">{item.amount}</:col>
        <:action :let={{_id, item}}>
          <div class="sr-only">
            <.link navigate={~p"/items/#{item}"}>Show</.link>
          </div>
          <.link navigate={~p"/items/#{item}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, item}}>
          <.link
            phx-click={JS.push("delete", value: %{id: item.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
        <:action :let={{_id, item}}>
          <.button phx-click={JS.push("increase_amount", value: %{id: item.id})}>
            Increase
          </.button>
        </:action>
        <:action :let={{_id, item}}>
          <.button phx-click={JS.push("decrease_amount", value: %{id: item.id})}>
            Decrease
          </.button>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Catalog.subscribe_items(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Items")
     |> stream(:items, list_items(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = Catalog.get_item!(socket.assigns.current_scope, id)
    {:ok, _} = Catalog.delete_item(socket.assigns.current_scope, item)

    {:noreply, stream_delete(socket, :items, item)}
  end

  def handle_event("increase_amount", %{"id" => id}, socket) do
    item = Catalog.get_item!(socket.assigns.current_scope, id)
    {:ok, _} = Catalog.increase_item_amount(socket.assigns.current_scope, item)

    {:noreply, stream(socket, :items, list_items(socket.assigns.current_scope), reset: true)}
  end

  def handle_event("decrease_amount", %{"id" => id}, socket) do
    with item = Catalog.get_item!(socket.assigns.current_scope, id),
         true <- item.amount > 0 do
      {:ok, _} = Catalog.decrease_item_amount(socket.assigns.current_scope, item)

      {:noreply, stream(socket, :items, list_items(socket.assigns.current_scope), reset: true)}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info({type, %OnlineShop.Catalog.Item{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :items, list_items(socket.assigns.current_scope), reset: true)}
  end

  defp list_items(current_scope) do
    Catalog.list_items(current_scope)
  end
end
