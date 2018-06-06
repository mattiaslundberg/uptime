defmodule UptimeGuiWeb.CheckChannel do
  use UptimeGuiWeb, :channel

  require Logger

  alias UptimeGui.{Check, Repo}

  def join("checks:" <> user_id, payload, socket) do
    if authorized?(user_id, payload) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    Check.get_all()
    |> Enum.map(fn c ->
      push(socket, "create_check", UptimeGui.Check.serialize(c))
    end)

    {:noreply, socket}
  end

  def handle_in("create_check", payload, socket) do
    case Check.create(payload) do
      {:ok, check} ->
        broadcast(socket, "create_check", Check.serialize(check))
        {:reply, {:ok, Check.serialize(check)}, socket}

      {:error, changeset} ->
        {:reply, {:error, changeset}, socket}
    end
  end

  def handle_in("update_check", payload, socket) do
    with id when not is_nil(id) <- Map.get(payload, "id"),
         check when not is_nil(check) <- UptimeGui.Repo.get(Check, id),
         {:ok, updated} <- UptimeGui.Repo.update(Check.changeset(check, payload)),
         serialized <- Check.serialize(updated) do
      broadcast(socket, "update_check", serialized)
      {:reply, {:ok, serialized}, socket}
    else
      {:error, changeset} ->
        {:reply, {:error, changeset}, socket}

      nil ->
        {:reply, {:error, %{"msg" => "Check not found"}}, socket}
    end
  end

  def handle_in("remove_check", payload, socket) do
    with id when not is_nil(id) <- Map.get(payload, "id"),
         check when not is_nil(check) <- Repo.get(Check, id),
         {:ok, check} = Repo.delete(check) do
      broadcast(socket, "remove_check", %{"id" => id})
      {:reply, {:ok, %{}}, socket}
    else
      nil ->
        {:reply, {:error, %{"msg" => "Check not found"}}, socket}
    end
  end

  defp authorized?(_user_id, _payload) do
    true
  end
end
