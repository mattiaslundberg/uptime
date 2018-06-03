defmodule CheckerTest do
  use ExUnit.Case, async: false

  alias Uptime.{Checker, Check}

  import Mock

  test "schedules and runs first check after start" do
    {:ok, pid} = Checker.start_link(%Check{})
    assert Process.alive?(pid)

    :erlang.trace(pid, true, [:receive])

    assert_receive({:trace, ^pid, :receive, :do_check}, 20)
  end

  test "performs check" do
    with_mocks([
      {Check, [], [perform_check: fn c -> c end]},
      {Check, [], [maybe_send_notification: fn c -> c end]}
    ]) do
      check = %Check{}
      Checker.handle_info(:do_check, check)

      assert called(Check.perform_check(check))
      assert called(Check.maybe_send_notification(check))
    end
  end

  test "updates state after check" do
    with_mocks([
      {Check, [], [perform_check: fn c -> %{c | failed_checks: c.failed_checks + 1} end]},
      {Check, [], [maybe_send_notification: fn c -> c end]}
    ]) do
      check = %Check{}
      {:noreply, check} = Checker.handle_info(:do_check, check)
      {:noreply, check} = Checker.handle_info(:do_check, check)

      assert check.failed_checks == 2
    end
  end
end
