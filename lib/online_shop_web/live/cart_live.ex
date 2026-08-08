defmodule OnlineShopWeb.CartLive do
  use OnlineShopWeb, :live_view

  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    items = OnlineShop.Cart.list_available_items(scope)
    cart_items = OnlineShop.Cart.list_cart_items(scope)
    {:ok, totals} = OnlineShop.Cart.recalculate_totals(scope)

    {:ok,
     socket
     |> assign(:items, items)
     |> assign(:cart_items, cart_items)
     |> assign(:totals, totals)
     |> assign(:voucher_code, nil)}
  end

  defp refresh(socket) do
    scope = socket.assigns.current_scope
    items = OnlineShop.Cart.list_available_items(scope)
    cart_items = OnlineShop.Cart.list_cart_items(scope)
    {:ok, totals} = OnlineShop.Cart.recalculate_totals(scope, socket.assigns.voucher_code)

    socket
    |> assign(:items, items)
    |> assign(:cart_items, cart_items)
    |> assign(:totals, totals)
  end

  def handle_event("add", %{"item_code" => item_code, "quantity" => q}, socket) do
    qty = String.to_integer(q || "1")
    _ = OnlineShop.Cart.add_item_to_cart(socket.assigns.current_scope, item_code, qty)
    {:noreply, refresh(socket)}
  end

  def handle_event("update", %{"item_code" => item_code, "quantity" => q}, socket) do
    qty = String.to_integer(q || "1")
    _ = OnlineShop.Cart.update_quantity(socket.assigns.current_scope, item_code, qty)
    {:noreply, refresh(socket)}
  end

  def handle_event("remove", %{"item_code" => item_code}, socket) do
    _ = OnlineShop.Cart.remove_item(socket.assigns.current_scope, item_code)
    {:noreply, refresh(socket)}
  end

  def handle_event("apply_voucher", %{"code" => code}, socket) do
    _ = OnlineShop.Promotions.apply_voucher(socket.assigns.current_scope, code)
    socket = assign(socket, :voucher_code, code)
    {:noreply, refresh(socket)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <div class="rounded-3xl border border-base-300 bg-base-100/80 p-6 shadow-sm">
          <div class="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <div>
              <p class="text-sm font-semibold uppercase tracking-[0.2em] text-primary">Buyer cart</p>
              <h1 class="text-3xl font-semibold">Browse items and build your order</h1>
            </div>
            <div class="rounded-2xl bg-primary/10 px-4 py-3 text-sm text-primary">
              <p class="font-medium">Subtotal: {@totals.subtotal_cents} cents</p>
              <p>Discount: {@totals.discount_cents} cents</p>
              <p class="font-semibold">Total: {@totals.total_cents} cents</p>
            </div>
          </div>
        </div>

        <div class="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
          <div class="rounded-3xl border border-base-300 bg-base-100/80 p-6 shadow-sm">
            <div class="mb-4 flex items-center justify-between">
              <h2 class="text-xl font-semibold">Available items</h2>
              <span class="rounded-full bg-base-200 px-3 py-1 text-sm">{length(@items)} available</span>
            </div>

            <div :if={@items == []} class="rounded-2xl border border-dashed border-base-300 p-8 text-center text-sm text-base-content/70">
              No items are currently available.
            </div>

            <div :for={item <- @items} class="flex flex-col gap-3 rounded-2xl border border-base-200 bg-base-200/40 p-4 md:flex-row md:items-center md:justify-between">
              <div>
                <p class="font-semibold">{item.name}</p>
                <p class="text-sm text-base-content/70">{item.item_code} • {item.category}</p>
                <p class="mt-1 text-sm font-medium">{item.price_cents} cents</p>
              </div>

              <form phx-submit="add" class="flex items-center gap-2">
                <input type="hidden" name="item_code" value={item.item_code} />
                <input type="number" name="quantity" value="1" min="1" class="input input-sm w-20" />
                <button class="btn btn-primary btn-sm">
                  <.icon name="hero-plus" class="size-4" />
                  <span class="ml-1">Add</span>
                </button>
              </form>
            </div>
          </div>

          <div class="rounded-3xl border border-base-300 bg-base-100/80 p-6 shadow-sm">
            <div class="mb-4 flex items-center justify-between">
              <h2 class="text-xl font-semibold">Your cart</h2>
              <span class="rounded-full bg-primary/10 px-3 py-1 text-sm text-primary">{length(@cart_items)} items</span>
            </div>

            <div :if={@cart_items == []} class="rounded-2xl border border-dashed border-base-300 p-8 text-center text-sm text-base-content/70">
              Your cart is empty. Start by adding an item.
            </div>

            <div :for={ci <- @cart_items} class="rounded-2xl border border-base-200 bg-base-200/40 p-4">
              <div class="flex items-start justify-between gap-4">
                <div>
                  <p class="font-semibold">{ci.item_code}</p>
                  <p class="text-sm text-base-content/70">Quantity: {ci.quantity}</p>
                </div>
                <div class="flex items-center gap-2">
                  <form phx-submit="remove" class="inline-flex">
                    <input type="hidden" name="item_code" value={ci.item_code} />
                    <button class="btn btn-ghost btn-sm">Remove</button>
                  </form>
                </div>
              </div>

              <form phx-submit="update" class="mt-3 flex items-center gap-2">
                <input type="hidden" name="item_code" value={ci.item_code} />
                <input type="number" name="quantity" value={ci.quantity} min="1" class="input input-sm w-20" />
                <button class="btn btn-outline btn-sm">Update</button>
              </form>
            </div>

            <form phx-submit="apply_voucher" class="mt-6 flex flex-col gap-2 rounded-2xl border border-base-200 bg-base-200/40 p-4 sm:flex-row">
              <input type="text" name="code" placeholder="Voucher code" class="input input-sm flex-1" />
              <button class="btn btn-secondary btn-sm">
                <.icon name="hero-ticket" class="size-4" />
                <span class="ml-1">Apply</span>
              </button>
            </form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
