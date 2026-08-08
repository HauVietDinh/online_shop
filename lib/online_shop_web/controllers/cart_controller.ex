defmodule OnlineShopWeb.CartController do
  use OnlineShopWeb, :controller

  def add(conn, %{"item_code" => item_code, "quantity" => q}) do
    scope = conn.assigns.current_scope
    qty = String.to_integer(q || "1")

    case OnlineShop.Cart.add_item_to_cart(scope, item_code, qty) do
      {:ok, item} ->
        json(conn, %{ok: true, item: %{item_code: item.item_code, quantity: item.quantity}})

      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> json(%{ok: false})
    end
  end

  def update(conn, %{"item_code" => item_code, "quantity" => q}) do
    scope = conn.assigns.current_scope
    qty = String.to_integer(q || "1")

    case OnlineShop.Cart.update_quantity(scope, item_code, qty) do
      {:ok, item} -> json(conn, %{ok: true, item: %{item_code: item.item_code, quantity: item.quantity}})
      {:error, _} -> conn |> put_status(:bad_request) |> json(%{ok: false})
    end
  end

  def remove(conn, %{"item_code" => item_code}) do
    scope = conn.assigns.current_scope
    _ = OnlineShop.Cart.remove_item(scope, item_code)
    json(conn, %{ok: true})
  end

  def apply_voucher(conn, %{"code" => code}) do
    scope = conn.assigns.current_scope

    case OnlineShop.Promotions.apply_voucher(scope, code) do
      {:ok, voucher} -> json(conn, %{ok: true, voucher_id: voucher.id})
      {:error, _} -> conn |> put_status(:bad_request) |> json(%{ok: false})
    end
  end
end
