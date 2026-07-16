defmodule OnlineShop.CatalogTest do
  use OnlineShop.DataCase

  alias OnlineShop.Catalog

  describe "items" do
    alias OnlineShop.Catalog.Item

    import OnlineShop.AccountsFixtures, only: [user_scope_fixture: 0]
    import OnlineShop.CatalogFixtures

    @invalid_attrs %{name: nil, category: nil, amount: nil, item_code: nil, price_cents: nil}

    test "list_items/1 returns all scoped items" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      item = item_fixture(scope)
      other_item = item_fixture(other_scope)
      assert Catalog.list_items(scope) == [item]
      assert Catalog.list_items(other_scope) == [other_item]
    end

    test "get_item!/2 returns the item with given id" do
      scope = user_scope_fixture()
      item = item_fixture(scope)
      other_scope = user_scope_fixture()
      assert Catalog.get_item!(scope, item.id) == item
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_item!(other_scope, item.id) end
    end

    test "create_item/2 with valid data creates a item" do
      valid_attrs = %{
        name: "some name",
        category: "some category",
        amount: 42,
        item_code: "some item_code",
        price_cents: 42
      }

      scope = user_scope_fixture()

      assert {:ok, %Item{} = item} = Catalog.create_item(scope, valid_attrs)
      assert item.name == "some name"
      assert item.category == "some category"
      assert item.amount == 42
      assert item.item_code == "some item_code"
      assert item.price_cents == 42
      assert item.user_id == scope.user.id
    end

    test "create_item/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Catalog.create_item(scope, @invalid_attrs)
    end

    test "update_item/3 with valid data updates the item" do
      scope = user_scope_fixture()
      item = item_fixture(scope)

      update_attrs = %{
        name: "some updated name",
        category: "some updated category",
        amount: 43,
        item_code: "some updated item_code",
        price_cents: 43
      }

      assert {:ok, %Item{} = item} = Catalog.update_item(scope, item, update_attrs)
      assert item.name == "some updated name"
      assert item.category == "some updated category"
      assert item.amount == 43
      assert item.item_code == "some updated item_code"
      assert item.price_cents == 43
    end

    test "update_item/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      item = item_fixture(scope)

      assert_raise MatchError, fn ->
        Catalog.update_item(other_scope, item, %{})
      end
    end

    test "update_item/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      item = item_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Catalog.update_item(scope, item, @invalid_attrs)
      assert item == Catalog.get_item!(scope, item.id)
    end

    test "delete_item/2 deletes the item" do
      scope = user_scope_fixture()
      item = item_fixture(scope)
      assert {:ok, %Item{}} = Catalog.delete_item(scope, item)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_item!(scope, item.id) end
    end

    test "delete_item/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      item = item_fixture(scope)
      assert_raise MatchError, fn -> Catalog.delete_item(other_scope, item) end
    end

    test "change_item/2 returns a item changeset" do
      scope = user_scope_fixture()
      item = item_fixture(scope)
      assert %Ecto.Changeset{} = Catalog.change_item(scope, item)
    end
  end
end
