defmodule UptimeGuiWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel("checks:*", UptimeGuiWeb.CheckChannel)

  ## Transports
  transport(:websocket, Phoenix.Transports.WebSocket)

  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(socket), do: "user:#{socket.assigns.user.id}"
end
