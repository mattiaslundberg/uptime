defmodule CheckTest do
  use ExUnit.Case, async: false

  alias Uptime.{Check, DummySender}

  import Mock

  describe "perform_check/1" do
    test_with_mock "perform successful check", HTTPotion,
      get: fn _url -> %HTTPotion.Response{status_code: 200} end do
      check =
        %Check{url: "https://test.com"}
        |> Check.perform_check()

      assert check.failed_checks == 0
      assert called(HTTPotion.get("https://test.com"))
    end

    test_with_mock "perform failing check", HTTPotion,
      get: fn _url -> %HTTPotion.Response{status_code: 500} end do
      check =
        %Check{url: "https://test.com"}
        |> Check.perform_check()

      assert check.failed_checks == 1
      assert called(HTTPotion.get("https://test.com"))
    end

    test_with_mock "successful check restores counters", HTTPotion,
      get: fn _url -> %HTTPotion.Response{status_code: 200} end do
      check =
        %Check{url: "https://test.com", failed_checks: 4, alert_sent: true}
        |> Check.perform_check()

      assert check.failed_checks == 0
      assert check.alert_sent == false
    end
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
