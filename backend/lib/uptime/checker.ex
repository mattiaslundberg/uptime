defmodule Uptime.Checker do
  use GenServer

  alias Uptime.Check

  def start_link(check = %Check{}) do
    GenServer.start_link(__MODULE__, check)
  end

  def stop(pid) do
    Process.exit(pid, :stopped)
  end

  def init(check) do
    schedule()
    {:ok, check}
  end

  def handle_info(:do_check, check = %Check{}) do
    check =
      check
      |> Check.perform_check()
      |> Check.maybe_send_notification()

    schedule(check.check_interval)
    {:noreply, check}
  end

  defp schedule(check_interval \\ 0) do
    Process.send_after(self(), :do_check, check_interval)
  end
end
