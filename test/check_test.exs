defmodule CheckTest do
  use ExUnit.Case, async: false

  alias Uptime.{Check, DummySender}

  describe "perform_check/1" do
  end

  describe "maybe_send_notification/1" do
    setup do
      DummySender.reset()
    end

    test "send notification when 3 fails" do
      c = %Check{url: "abc", notify_number: "+46123", failed_checks: 3}
      Check.maybe_send_notification(c, DummySender)

      [msg] = DummySender.get_messages()
      assert msg.to == "+46123"
      assert msg.msg == "Failed 3 checks for abc"
    end

    test "not sending when no failed notifications" do
      c = %Check{notify_number: "+46123"}

      Check.maybe_send_notification(c, DummySender)

      [] = DummySender.get_messages()
    end

    test "not sending multiple notifications" do
      %Check{url: "abc", notify_number: "+46123", failed_checks: 3}
      |> Check.maybe_send_notification(DummySender)
      |> Check.maybe_send_notification(DummySender)
      |> Check.maybe_send_notification(DummySender)

      [_] = DummySender.get_messages()
    end
  end
end
