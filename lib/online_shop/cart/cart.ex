defmodule OnlineShop.Cart.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  schema "carts" do
    field :user_id, :id
    has_many :items, OnlineShop.Cart.CartItem, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  def changeset(cart, attrs) do
    cart
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end
end
