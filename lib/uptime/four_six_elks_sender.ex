defmodule Uptime.FourSixElksSender do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def send_message(msg = %Uptime.Message{}) do
    GenServer.cast(__MODULE__, msg)
  end

  # Callbacks

  def init(_) do
    {:ok, nil}
  end

  def handle_cast(%Uptime.Message{to: to, msg: msg}) do
    IO.inspect ["Sending", to, msg]
    {:noreply, :ok}
  end
end
