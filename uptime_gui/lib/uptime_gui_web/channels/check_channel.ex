defmodule UptimeGuiWeb.CheckChannel do
  use UptimeGuiWeb, :channel

  require Logger

  alias UptimeGui.{Check, Repo, User, Contact}

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
    |> Enum.map(&push(socket, "create_check", Check.serialize(&1)))

    Contact.get_all(socket.assigns.user.id)
    |> Enum.map(&push(socket, "create_contact", Contact.serialize(&1)))

    {:noreply, socket}
  end

  def handle_in("create_check", payload, socket) do
    contact_ids = payload |> Map.get("contacts", []) |> Enum.uniq()

    with {:contacts, contacts} when length(contacts) == length(contact_ids) <-
           {:contacts, Contact.get_list(socket.assigns.user.id, contact_ids)},
         {:ok, check, _} <-
           Check.create(socket.assigns.user, contacts, Map.delete(payload, "notify_number")) do
      broadcast(socket, "create_check", Check.serialize(check))

      {:reply, {:ok, %{"status_msg" => "Successfully created new check", "check_id" => check.id}},
       socket}
    else
      {:error, changeset} ->
        send_error_reply(
          "Something went wrong when creating check",
          errors_from_changeset(changeset),
          socket
        )

      {:contacts, _} ->
        send_error_reply(
          "Something went wrong when creating check",
          %{"contacts" => "Invalid choice"},
          socket
        )
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
        send_error_reply(
          "Something went wrong when updating check",
          errors_from_changeset(changeset),
          socket
        )

      nil ->
        send_error_reply("Cannot update non existing check", %{}, socket)
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
        send_error_reply("Cannot remove non existing check", %{}, socket)
    end
  end

  defp send_error_reply(status_msg, errors, socket) do
    {:reply,
     {:error,
      %{
        "status_msg" => status_msg,
        "errors" => errors
      }}, socket}
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
