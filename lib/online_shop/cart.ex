defmodule OnlineShop.Cart do
  import Ecto.Query, warn: false
  alias OnlineShop.Repo
  alias OnlineShop.Accounts.Scope
  alias OnlineShop.Catalog
  alias OnlineShop.Cart.Cart
  alias OnlineShop.Cart.CartItem

  def list_available_items(%Scope{} = _scope) do
    from(i in Catalog.Item, where: i.amount > 0)
    |> Repo.all()
  end

  def get_or_create_cart(%Scope{} = scope) do
    case Repo.get_by(Cart, user_id: scope.user.id) do
      nil ->
        %Cart{}
        |> Cart.changeset(%{user_id: scope.user.id})
        |> Repo.insert!()

      cart ->
        cart
    end
  end

  def list_cart_items(%Scope{} = scope) do
    cart = get_or_create_cart(scope)

    from(ci in CartItem, where: ci.cart_id == ^cart.id)
    |> Repo.all()
  end

  def add_item_to_cart(%Scope{} = scope, item_code, quantity) when is_integer(quantity) and quantity > 0 do
    cart = get_or_create_cart(scope)

    case Repo.get_by(CartItem, cart_id: cart.id, item_code: item_code) do
      nil ->
        %CartItem{}
        |> CartItem.changeset(%{cart_id: cart.id, item_code: item_code, quantity: quantity})
        |> Repo.insert()

      existing_item ->
        existing_item
        |> CartItem.changeset(%{cart_id: cart.id, item_code: item_code, quantity: existing_item.quantity + quantity})
        |> Repo.update()
    end
  end

  def update_quantity(%Scope{} = scope, item_code, quantity) when is_integer(quantity) and quantity > 0 do
    cart = get_or_create_cart(scope)

    case Repo.get_by(CartItem, cart_id: cart.id, item_code: item_code) do
      nil ->
        {:error, :not_found}

      item ->
        item
        |> CartItem.changeset(%{cart_id: cart.id, item_code: item_code, quantity: quantity})
        |> Repo.update()
    end
  end

  def remove_item(%Scope{} = scope, item_code) do
    cart = get_or_create_cart(scope)

    case Repo.get_by(CartItem, cart_id: cart.id, item_code: item_code) do
      nil ->
        :ok

      item ->
        Repo.delete(item)
        :ok
    end
  end

  def recalculate_totals(%Scope{} = scope, voucher_code \\ nil) do
    items = list_cart_items(scope)

    subtotal_cents =
      Enum.reduce(items, 0, fn item, acc ->
        case Repo.get_by(OnlineShop.Catalog.Item, item_code: item.item_code) do
          nil -> acc
          catalog_item -> acc + item.quantity * catalog_item.price_cents
        end
      end)

    discount_cents =
      if voucher_code do
        case OnlineShop.Promotions.get_promotion_by_code(voucher_code) do
          nil -> 0
          promotion -> apply_discount(subtotal_cents, promotion)
        end
      else
        0
      end

    total_cents = max(0, subtotal_cents - discount_cents)
    {:ok, %{subtotal_cents: subtotal_cents, discount_cents: discount_cents, total_cents: total_cents}}
  end

  defp apply_discount(subtotal_cents, %{discount_type: "percent", discount_value: discount_value}) do
    round(subtotal_cents * discount_value / 100)
  end

  defp apply_discount(subtotal_cents, %{discount_type: "fixed", discount_value: discount_value}) do
    min(subtotal_cents, discount_value)
  end

  defp apply_discount(_, _), do: 0
end
