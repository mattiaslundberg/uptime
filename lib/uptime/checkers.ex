defmodule Uptime.Checkers do
  use GenServer

  alias Uptime.{Check, Checker}

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_) do
    {:ok, nil}
  end

  def add_check(check = %Check{}) do
    GenServer.call(__MODULE__, {:add, check})
  end

  def remove_check(check = %Check{pid: pid}) do
    :ok = GenServer.cast(__MODULE__, {:remove, pid})
    %{check | pid: nil}
  end

  def handle_call({:add, check = %Check{}}, _from, state) do
    {:ok, pid} = GenServer.start_link(Uptime.Checker, check)
    new_check = %{check | pid: pid}
    {:reply, new_check, state}
  end

  def handle_cast({:remove, pid}, state) do
    Checker.stop(pid)
    {:noreply, state}
  end
end
