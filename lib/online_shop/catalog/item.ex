defmodule OnlineShop.Catalog.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :item_code, :string
    field :name, :string
    field :category, :string
    field :price_cents, :integer
    field :amount, :integer
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs, user_scope) do
    item
    |> cast(attrs, [:item_code, :name, :category, :price_cents, :amount])
    |> validate_required([:item_code, :name, :category, :price_cents, :amount])
    |> validate_number(:price_cents, greater_than_or_equal_to: 0)
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> validate_length(:item_code, min: 3, max: 100)
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:category, min: 3, max: 50)
    |> put_change(:user_id, user_scope.user.id)
    |> unique_constraint(:item_code,
      name: :items_user_id_item_code_index,
      message: "item code must be unique per seller"
    )
  end

  def increase_amount_changeset(item, user_scope) do
    item
    |> change()
    |> put_change(:amount, item.amount + 1)
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> put_change(:user_id, user_scope.user.id)
  end

  def decrease_amount_changeset(item, user_scope) do
    item
    |> change()
    |> put_change(:amount, item.amount - 1)
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> put_change(:user_id, user_scope.user.id)
  end
end
