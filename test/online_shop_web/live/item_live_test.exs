defmodule OnlineShopWeb.ItemLiveTest do
  use OnlineShopWeb.ConnCase

  import Phoenix.LiveViewTest
  import OnlineShop.CatalogFixtures

  @create_attrs %{
    name: "some name",
    category: "some category",
    amount: 42,
    item_code: "some item_code",
    price_cents: 42
  }
  @update_attrs %{
    name: "some updated name",
    category: "some updated category",
    amount: 43,
    item_code: "some updated item_code",
    price_cents: 43
  }
  @invalid_attrs %{name: nil, category: nil, amount: nil, item_code: nil, price_cents: nil}

  setup :register_and_log_in_seller

  defp create_item(%{scope: scope}) do
    item = item_fixture(scope)

    %{item: item}
  end

  describe "Index" do
    setup [:create_item]

    test "lists all items", %{conn: conn, item: item} do
      {:ok, _index_live, html} = live(conn, ~p"/items")

      assert html =~ "Listing Items"
      assert html =~ item.item_code
    end

    test "saves new item", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/items")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Item")
               |> render_click()
               |> follow_redirect(conn, ~p"/items/new")

      assert render(form_live) =~ "New Item"

      assert form_live
             |> form("#item-form", item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#item-form", item: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/items")

      html = render(index_live)
      assert html =~ "Item created successfully"
      assert html =~ "some item_code"
    end

    test "updates item in listing", %{conn: conn, item: item} do
      {:ok, index_live, _html} = live(conn, ~p"/items")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#items-#{item.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/items/#{item}/edit")

      assert render(form_live) =~ "Edit Item"

      assert form_live
             |> form("#item-form", item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#item-form", item: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/items")

      html = render(index_live)
      assert html =~ "Item updated successfully"
      assert html =~ "some updated item_code"
    end

    test "deletes item in listing", %{conn: conn, item: item} do
      {:ok, index_live, _html} = live(conn, ~p"/items")

      assert index_live |> element("#items-#{item.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#items-#{item.id}")
    end

    test "increases item amount", %{conn: conn, item: item, scope: scope} do
      {:ok, index_live, _html} = live(conn, ~p"/items")

      index_live |> element("#items-#{item.id} button", "Increase") |> render_click()
      updated_item = OnlineShop.Catalog.get_item!(scope, item.id)

      assert updated_item.amount == item.amount + 1
    end

    test "decreases item amount", %{conn: conn, item: item, scope: scope} do
      {:ok, index_live, _html} = live(conn, ~p"/items")

      index_live |> element("#items-#{item.id} button", "Decrease") |> render_click()
      updated_item = OnlineShop.Catalog.get_item!(scope, item.id)

      assert updated_item.amount == item.amount - 1
    end

    test "does not decrease amount below zero", %{conn: conn, scope: scope} do
      item = item_fixture(scope, %{amount: 0})

      {:ok, index_live, _html} = live(conn, ~p"/items")

      index_live |> element("#items-#{item.id} button", "Decrease") |> render_click()

      # Amount should remain 0, not go negative
      assert OnlineShop.Catalog.get_item!(scope, item.id).amount == 0
    end

    test "cannot create item with duplicate item_code for same seller", %{
      conn: conn,
      scope: scope
    } do
      # Create first item
      _item1 = item_fixture(scope, %{item_code: "DUP-001"})

      {:ok, index_live, _html} = live(conn, ~p"/items")

      # Navigate to new item form
      {:ok, form_live, _} =
        index_live
        |> element("a", "New Item")
        |> render_click()
        |> follow_redirect(conn, ~p"/items/new")

      # Try to create second item with same code
      form_live
      |> form("#item-form",
        item: %{
          name: "Duplicate",
          category: "test",
          amount: 10,
          # Same as item1
          item_code: "DUP-001",
          price_cents: 100
        }
      )
      |> render_submit()

      # Should NOT redirect (form stays, shows error)
      assert render(form_live) =~ "item code must be unique per seller"
    end

    test "item cannot have negative price", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/items")

      {:ok, form_live, _} =
        index_live
        |> element("a", "New Item")
        |> render_click()
        |> follow_redirect(conn, ~p"/items/new")

      # Try to create item with negative price
      form_live
      |> form("#item-form",
        item: %{
          name: "Bad Price",
          category: "test",
          amount: 10,
          item_code: "NEG-PRICE",
          # Negative!
          price_cents: -100
        }
      )
      |> render_change()

      # Should show validation error
      assert render(form_live) =~ "must be greater than or equal to 0"
    end

    test "item cannot have negative amount", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/items")

      {:ok, form_live, _} =
        index_live
        |> element("a", "New Item")
        |> render_click()
        |> follow_redirect(conn, ~p"/items/new")

      # Try to create item with negative amount
      form_live
      |> form("#item-form",
        item: %{
          name: "Bad Amount",
          category: "test",
          # Negative!
          amount: -5,
          item_code: "NEG-AMT",
          price_cents: 100
        }
      )
      |> render_change()

      # Should show validation error
      assert render(form_live) =~ "must be greater than or equal to 0"
    end
  end

  describe "Show" do
    setup [:create_item]

    test "displays item", %{conn: conn, item: item} do
      {:ok, _show_live, html} = live(conn, ~p"/items/#{item}")

      assert html =~ "Show Item"
      assert html =~ item.item_code
    end

    test "updates item and returns to show", %{conn: conn, item: item} do
      {:ok, show_live, _html} = live(conn, ~p"/items/#{item}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/items/#{item}/edit?return_to=show")

      assert render(form_live) =~ "Edit Item"

      assert form_live
             |> form("#item-form", item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#item-form", item: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/items/#{item}")

      html = render(show_live)
      assert html =~ "Item updated successfully"
      assert html =~ "some updated item_code"
    end
  end

  describe "Authorization" do
    test "buyer is redirected from /items", %{conn: conn} do
      # Register and log in as BUYER (not seller)
      buyer = OnlineShop.AccountsFixtures.user_fixture(%{role: "Buyer"})
      buyer_conn = OnlineShopWeb.ConnCase.log_in_user(conn, buyer)

      # Attempt to access seller-only route
      conn = get(buyer_conn, "/items")

      # Should redirect (to home or login)
      assert redirected_to(conn) in ["/", "/users/log_in"]
    end

    test "seller cannot edit another seller's item", %{conn: conn} do
      # Create two sellers
      seller1 = OnlineShop.AccountsFixtures.user_fixture(%{role: "Seller"})
      seller2 = OnlineShop.AccountsFixtures.user_fixture(%{role: "Seller"})

      scope1 = OnlineShop.Accounts.Scope.for_user(seller1)

      # Seller1 creates an item
      item = OnlineShop.CatalogFixtures.item_fixture(scope1)

      # Log in as seller2
      seller2_conn = OnlineShopWeb.ConnCase.log_in_user(conn, seller2)

      # Seller2 tries to edit seller1's item
      assert_raise Ecto.NoResultsError, fn ->
        live(seller2_conn, ~p"/items/#{item}")
      end
    end
  end
end
