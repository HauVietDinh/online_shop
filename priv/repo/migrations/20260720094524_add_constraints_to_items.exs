defmodule OnlineShop.Repo.Migrations.AddConstraintsToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      modify :item_code, :string, null: false
      modify :name, :string, null: false
      modify :category, :string, null: false
      modify :price_cents, :integer, null: false
      modify :amount, :integer, null: false
    end

    create constraint(:items, :price_cents_must_be_non_negative, check: "price_cents >= 0")
    create constraint(:items, :amount_must_be_non_negative, check: "amount >= 0")
    create unique_index(:items, [:user_id, :item_code])
  end
end
