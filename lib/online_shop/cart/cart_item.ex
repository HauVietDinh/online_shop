defmodule OnlineShop.Cart.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field :cart_id, :id
    field :item_code, :string
    field :quantity, :integer, default: 1

    timestamps(type: :utc_datetime)
  end

  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:cart_id, :item_code, :quantity])
    |> validate_required([:cart_id, :item_code, :quantity])
    |> validate_number(:quantity, greater_than: 0)
  end
end
