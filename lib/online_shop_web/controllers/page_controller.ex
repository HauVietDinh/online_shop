defmodule OnlineShopWeb.PageController do
  use OnlineShopWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
