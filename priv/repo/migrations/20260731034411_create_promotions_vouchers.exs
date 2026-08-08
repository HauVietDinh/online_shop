defmodule OnlineShop.Repo.Migrations.CreatePromotionsVouchers do
  use Ecto.Migration

  def change do
    create table(:promotions) do
      add :name, :string, null: false
      add :code, :string, null: false
      add :discount_type, :string, null: false
      add :discount_value, :integer, null: false
      add :start_date, :utc_datetime, null: false
      add :end_date, :utc_datetime
      add :is_active, :boolean, default: true, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:promotions, :code)

    create table(:vouchers) do
      add :promotion_id, references(:promotions, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :code, :string, null: false
      add :used_at, :utc_datetime
      add :status, :string, default: "unused", null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:vouchers, :code)
    create index(:vouchers, :promotion_id)
    create index(:vouchers, :user_id)
  end
end
