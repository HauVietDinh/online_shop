defmodule OnlineShop.Repo.Migrations.CreateCartsAndCardItems do
  use Ecto.Migration

  def change do
    create table(:carts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:carts, :user_id)

    create table(:cart_items) do
      add :cart_id, references(:carts, on_delete: :delete_all), null: false
      add :item_code, :string, null: false
      add :quantity, :integer, default: 1, null: false
      timestamps(type: :utc_datetime)
    end

    create index(:cart_items, :cart_id)
    create unique_index(:cart_items, [:cart_id, :item_code])
  end
end
