defmodule OnlineShop.Catalog do
  @moduledoc """
  The Catalog context.
  """

  import Ecto.Query, warn: false
  alias OnlineShop.Repo

  alias OnlineShop.Catalog.Item
  alias OnlineShop.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any item changes.

  The broadcasted messages match the pattern:

    * {:created, %Item{}}
    * {:updated, %Item{}}
    * {:deleted, %Item{}}

  """
  def subscribe_items(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(OnlineShop.PubSub, "user:#{key}:items")
  end

  defp broadcast_item(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(OnlineShop.PubSub, "user:#{key}:items", message)
  end

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items(scope)
      [%Item{}, ...]

  """
  def list_items(%Scope{} = scope) do
    Repo.all_by(Item, user_id: scope.user.id)
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(scope, 123)
      %Item{}

      iex> get_item!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(%Scope{} = scope, id) do
    Repo.get_by!(Item, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(scope, %{field: value})
      {:ok, %Item{}}

      iex> create_item(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(%Scope{} = scope, attrs) do
    with {:ok, item = %Item{}} <-
           %Item{}
           |> Item.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_item(scope, {:created, item})
      {:ok, item}
    end
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(scope, item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(scope, item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Scope{} = scope, %Item{} = item, attrs) do
    true = item.user_id == scope.user.id

    with {:ok, item = %Item{}} <-
           item
           |> Item.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_item(scope, {:updated, item})
      {:ok, item}
    end
  end

  @doc """
  Deletes a item.

  ## Examples

      iex> delete_item(scope, item)
      {:ok, %Item{}}

      iex> delete_item(scope, item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Scope{} = scope, %Item{} = item) do
    true = item.user_id == scope.user.id

    with {:ok, item = %Item{}} <-
           Repo.delete(item) do
      broadcast_item(scope, {:deleted, item})
      {:ok, item}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(scope, item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item(%Scope{} = scope, %Item{} = item, attrs \\ %{}) do
    true = item.user_id == scope.user.id

    Item.changeset(item, attrs, scope)
  end

  def increase_item_amount(%Scope{} = scope, %Item{} = item) do
    true = item.user_id == scope.user.id

    with {:ok, item = %Item{}} <-
           item
           |> Item.increase_amount_changeset(scope)
           |> Repo.update() do
      broadcast_item(scope, {:updated, item})
      {:ok, item}
    end
  end

  def decrease_item_amount(%Scope{} = scope, %Item{} = item) do
    true = item.user_id == scope.user.id

    with {:ok, item = %Item{}} <-
           item
           |> Item.decrease_amount_changeset(scope)
           |> Repo.update() do
      broadcast_item(scope, {:updated, item})
      {:ok, item}
    end
  end
end
