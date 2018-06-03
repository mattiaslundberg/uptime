defmodule Uptime.Checker do
  use GenServer

  alias Uptime.Check

  def start_link(check = %Check{}) do
    GenServer.start_link(__MODULE__, check)
  end

  def stop(pid) do
    send(pid, :stop)
  end

  def init(_) do
    {:ok, nil}
  end
end
