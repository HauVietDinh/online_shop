defmodule OnlineShop.PromotionsTest do
  use OnlineShop.DataCase

  alias OnlineShop.Promotions
  alias OnlineShop.Promotions.Voucher

  import OnlineShop.AccountsFixtures, only: [user_scope_fixture: 0]

  test "apply_voucher/3 stores the voucher against the buyer scope" do
    scope = user_scope_fixture()

    assert {:ok, %OnlineShop.Promotions.Promotion{} = promotion} =
             Promotions.create_promotion(%{
               name: "Summer",
               code: "SUMMER10",
               discount_type: "percent",
               discount_value: 10,
               start_date: DateTime.utc_now(),
               end_date: DateTime.add(DateTime.utc_now(), 86_400, :second),
               is_active: true
             })

    assert {:ok, %Voucher{} = applied} = Promotions.apply_voucher(scope, promotion.code)
    assert applied.promotion_id == promotion.id
    assert applied.user_id == scope.user.id
  end
end
