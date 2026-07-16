defmodule OnlineShop.Repo.Migrations.RemoveSellerIdFromItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      remove :seller_id
    end
  end
end
