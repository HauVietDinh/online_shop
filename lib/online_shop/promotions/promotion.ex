defmodule OnlineShop.Promotions.Promotion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "promotions" do
    field :name, :string
    field :code, :string
    field :discount_type, :string
    field :discount_value, :integer
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime
    field :is_active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  def changeset(promotion, attrs) do
    promotion
    |> cast(attrs, [:name, :code, :discount_type, :discount_value, :start_date, :end_date, :is_active])
    |> validate_required([:name, :code, :discount_type, :discount_value, :start_date, :is_active])
    |> unique_constraint(:code)
  end
end
