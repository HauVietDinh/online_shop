defmodule OnlineShop.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :item_code, :string
      add :name, :string
      add :category, :string
      add :price_cents, :integer
      add :amount, :integer
      add :seller_id, references(:users, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:items, [:user_id])

    create index(:items, [:seller_id])
  end
end
