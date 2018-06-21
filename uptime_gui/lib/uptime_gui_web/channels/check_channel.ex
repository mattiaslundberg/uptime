defmodule UptimeGuiWeb.CheckChannel do
  use UptimeGuiWeb, :channel

  require Logger

  alias UptimeGui.{Check, Repo, User}

  def join("checks:" <> user_id, payload, socket) do
    with true <- authorized?(user_id, payload),
         user = %User{} <- Repo.get(User, user_id) do
      socket = assign(socket, :user, user)

      send(self(), :after_join)
      {:ok, socket}
    else
      false ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    Check.get_all(socket.assigns.user.id)
    |> Enum.map(fn c ->
      push(socket, "create_check", UptimeGui.Check.serialize(c))
    end)

    {:noreply, socket}
  end

  def handle_in("create_check", payload, socket) do
    case Check.create(socket.assigns.user, payload) do
      {:ok, check, _} ->
        broadcast(socket, "create_check", Check.serialize(check))

        {:reply,
         {:ok, %{"status_msg" => "Successfully created new check", "check_id" => check.id}},
         socket}

      {:error, changeset} ->
        {:reply,
         {:error,
          %{
            "status_msg" => "Something went wrong when creating check",
            "errors" => errors_from_changeset(changeset)
          }}, socket}
    end
  end

  def handle_in("update_check", payload, socket) do
    with id when not is_nil(id) <- Map.get(payload, "id"),
         check when not is_nil(check) <- Check.get(socket.assigns.user.id, id),
         {:ok, updated} <- UptimeGui.Repo.update(Check.changeset(check, payload)),
         serialized <- Check.serialize(updated) do
      broadcast(socket, "update_check", serialized)
      {:reply, {:ok, %{"status_msg" => "Successfully updated check", "check_id" => id}}, socket}
    else
      {:error, changeset} ->
        {:reply,
         {:error,
          %{
            "status_msg" => "Something went wrong when updating check",
            "errors" => errors_from_changeset(changeset)
          }}, socket}

      nil ->
        {:reply, {:error, %{"status_msg" => "Cannot update non existing check", "errors" => %{}}},
         socket}
    end
  end

  def handle_in("remove_check", payload, socket) do
    with id when not is_nil(id) <- Map.get(payload, "id"),
         check when not is_nil(check) <- Check.get(socket.assigns.user.id, id),
         {:ok, _check} = Repo.delete(check) do
      broadcast(socket, "remove_check", %{"id" => id})
      {:reply, {:ok, %{"status_msg" => "Successfully removed check", "check_id" => id}}, socket}
    else
      nil ->
        {:reply, {:error, %{"status_msg" => "Cannot remove non existing check", "errors" => %{}}},
         socket}
    end
  end

  defp errors_from_changeset(%{errors: errors}) do
    Enum.reduce(errors, %{}, fn {field, {message, _}}, r ->
      Map.put(r, Atom.to_string(field), message)
    end)
  end

  defp authorized?(user_id_str, payload) do
    with {user_id, ""} <- Integer.parse(user_id_str),
         token <- Map.get(payload, "token", ""),
         {:ok, %{"user_id" => ^user_id}} <- User.token_data(token) do
      true
    else
      _ ->
        false
    end
  end
end
