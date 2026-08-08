defmodule OnlineShop.Promotions do
  import Ecto.Query, warn: false
  alias OnlineShop.Repo
  alias OnlineShop.Promotions.Promotion
  alias OnlineShop.Promotions.Voucher
  alias OnlineShop.Accounts.Scope

  def list_promotions do
    Repo.all(Promotion)
  end

  def create_promotion(attrs) do
    %Promotion{}
    |> Promotion.changeset(attrs)
    |> Repo.insert()
  end

  def get_promotion_by_code(code) do
    Repo.get_by(Promotion, code: code)
  end

  def apply_voucher(%Scope{} = scope, code) do
    promotion = get_promotion_by_code(code)

    cond do
      is_nil(promotion) ->
        {:error, :not_found}

      not promotion.is_active ->
        {:error, :inactive}

      true ->
        %Voucher{}
        |> Voucher.changeset(%{promotion_id: promotion.id, user_id: scope.user.id, code: code, status: "used"})
        |> Repo.insert()
    end
  end

  def recalculate_totals(%Scope{} = _scope, subtotal_cents, discount_cents) do
    total_cents = max(0, subtotal_cents - discount_cents)
    {:ok, %{subtotal_cents: subtotal_cents, discount_cents: discount_cents, total_cents: total_cents}}
  end
end
