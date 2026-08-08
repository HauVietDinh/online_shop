defmodule OnlineShop.Promotions.Voucher do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vouchers" do
    field :promotion_id, :id
    field :user_id, :id
    field :code, :string
    field :used_at, :utc_datetime
    field :status, :string, default: "unused"

    timestamps(type: :utc_datetime)
  end

  def changeset(voucher, attrs) do
    voucher
    |> cast(attrs, [:promotion_id, :user_id, :code, :used_at, :status])
    |> validate_required([:promotion_id, :user_id, :code, :status])
    |> unique_constraint(:code)
  end
end
