defmodule Uptime.DummySender do
  use GenServer

  alias Uptime.Message

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def reset do
    GenServer.cast(__MODULE__, :reset)
  end

  def send_message(msg = %Message{}) do
    GenServer.cast(__MODULE__, msg)
  end

  def get_messages do
    GenServer.call(__MODULE__, :get_all)
  end

  def init(_) do
    {:ok, []}
  end

  def handle_cast(:reset, _state) do
    {:noreply, []}
  end

  def handle_cast(msg = %Message{}, state) do
    {:noreply, [msg | state]}
  end

  def handle_call(:get_all, _from, state) do
    {:reply, state, state}
  end
end
