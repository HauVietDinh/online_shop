defmodule OnlineShop.CartTest do
  use OnlineShop.DataCase

  alias OnlineShop.Cart
  alias OnlineShop.Cart.CartItem
  alias OnlineShop.Catalog.Item

  import OnlineShop.AccountsFixtures, only: [user_scope_fixture: 0]
  import OnlineShop.CatalogFixtures

  test "list_available_items/1 returns only items with stock" do
    seller_scope = user_scope_fixture()
    buyer_scope = user_scope_fixture()

    item_fixture(seller_scope, %{amount: 5, price_cents: 5000, item_code: "ITEM-1", name: "Laptop"})
    item_fixture(seller_scope, %{amount: 0, price_cents: 3000, item_code: "ITEM-2", name: "Mouse"})

    items = Cart.list_available_items(buyer_scope)

    assert length(items) == 1
    assert [%Item{name: "Laptop", amount: 5}] = items
  end

  test "add_item_to_cart/3 creates a cart entry and updates quantity" do
    seller_scope = user_scope_fixture()
    buyer_scope = user_scope_fixture()
    item = item_fixture(seller_scope, %{amount: 10, price_cents: 4000, item_code: "ITEM-3", name: "Keyboard"})

    assert {:ok, %CartItem{} = cart_item} = Cart.add_item_to_cart(buyer_scope, item.item_code, 1)
    assert cart_item.quantity == 1
    assert cart_item.item_code == item.item_code

    assert {:ok, %CartItem{} = updated_item} = Cart.add_item_to_cart(buyer_scope, item.item_code, 2)
    assert updated_item.quantity == 3
  end

  test "update_quantity/3 and remove_item/2 change the cart" do
    seller_scope = user_scope_fixture()
    buyer_scope = user_scope_fixture()
    item = item_fixture(seller_scope, %{amount: 10, price_cents: 2500, item_code: "ITEM-4", name: "Headphones"})

    assert {:ok, _} = Cart.add_item_to_cart(buyer_scope, item.item_code, 1)
    assert {:ok, %CartItem{} = updated_item} = Cart.update_quantity(buyer_scope, item.item_code, 3)
    assert updated_item.quantity == 3

    assert :ok = Cart.remove_item(buyer_scope, item.item_code)
    assert [] = Cart.list_cart_items(buyer_scope)
  end
end
