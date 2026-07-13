defmodule OnlineShopWeb.UserLive.ConfirmationTest do
  use OnlineShopWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import OnlineShop.AccountsFixtures

  alias OnlineShop.Accounts

  setup do
    %{unconfirmed_user: unconfirmed_user_fixture(), confirmed_user: user_fixture()}
  end

  describe "Confirm user" do
    test "renders confirmation page for unconfirmed user", %{conn: conn, unconfirmed_user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/users/log-in/#{token}")

      assert has_element?(lv, "#login_form")
    end

    test "renders login page for confirmed user", %{conn: conn, confirmed_user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_confirmation_instructions(user, url)
        end)

      {:ok, lv, html} = live(conn, ~p"/users/log-in/#{token}")

      refute has_element?(lv, "#login_form")
      assert html =~ user.email
    end

    test "renders login page for already logged in user", %{conn: conn, confirmed_user: user} do
      conn = log_in_user(conn, user)

      token =
        extract_user_token(fn url ->
          Accounts.deliver_confirmation_instructions(user, url)
        end)

      {:ok, lv, html} = live(conn, ~p"/users/log-in/#{token}")

      refute has_element?(lv, "#login_form")
      assert html =~ user.email
    end

    test "confirms the given token once", %{conn: conn, unconfirmed_user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/users/log-in/#{token}")

      form = form(lv, "#login_form", %{"user" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Accounts.get_user!(user.id).confirmed_at
      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      assert {:error, {:live_redirect, %{to: "/users/log-in"}}} =
               live(build_conn(), ~p"/users/log-in/#{token}")
    end

    test "logs confirmed user in without changing confirmed_at", %{
      conn: conn,
      confirmed_user: user
    } do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/users/log-in/#{token}")

      refute has_element?(lv, "#login_form")
      assert Accounts.get_user!(user.id).confirmed_at == user.confirmed_at
    end

    test "raises error for invalid token", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/users/log-in"}}} =
               live(conn, ~p"/users/log-in/invalid-token")
    end
  end
end
