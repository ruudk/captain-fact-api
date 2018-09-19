defmodule CaptainFact.Statements do
  @moduledoc """
  Functions to manipulate statements
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Kaur.Result

  alias DB.Schema.Statement
  alias DB.Repo

  alias CaptainFact.Accounts.UserPermissions
  import CaptainFact.Actions.ActionCreator, only: [action_update: 2]

  @doc """
  Update given statement. Will raise if user doesn't have
  permission to do that.
  """
  def update!(user_id, statement = %Statement{is_removed: false}, changes) do
    UserPermissions.check!(user_id, :update, :statement)
    changeset = Statement.changeset(statement, changes)

    if changeset.changes == %{} do
      Result.ok(statement)
    else
      Multi.new()
      |> Multi.update(:statement, changeset)
      |> Multi.insert(:action_update, action_update(user_id, changeset))
      |> Repo.transaction()
      |> case do
        {:ok, %{statement: updated_statement}} ->
          Result.ok(updated_statement)

        {:error, _operation, reason, _changes} ->
          Result.error(reason)
      end
    end
  end

  @doc """
  Get all statements without comments
  """
  def statements_without_comments() do
    Statement
    |> join(:left, [s], c in assoc(s, :comments))
    |> where([_, c], is_nil(c.id))
    |> Repo.all()
  end
end
