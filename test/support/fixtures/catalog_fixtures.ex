defmodule OnlineShop.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OnlineShop.Catalog` context.
  """

  @doc """
  Generate a item.
  """
  def item_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        amount: 42,
        category: "some category",
        item_code: "ITEM-#{System.unique_integer([:positive])}",
        name: "some name",
        price_cents: 42
      })

    {:ok, item} = OnlineShop.Catalog.create_item(scope, attrs)
    item
  end
end
