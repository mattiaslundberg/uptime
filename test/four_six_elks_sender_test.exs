defmodule FourSixElksSenderTest do
  use ExUnit.Case, async: false

  alias Uptime.FourSixElksSender
  alias Uptime.Message

  require Logger

  import ExUnit.CaptureLog
  import Mock

  describe "send_message/1" do
    test_with_mock "sends successful response", HTTPotion,
      post: fn _url, _data ->
        %HTTPotion.Response{status_code: 200, body: "{\"status\": \"created\"}"}
      end do
      capture_log(fn ->
        m = %Message{to: "me", msg: "Warning"}
        FourSixElksSender.send_message(m)
      end)
    end
  end

  describe "handle_cast/2" do
    test_with_mock "successful response", HTTPotion,
      post: fn _url, _data ->
        %HTTPotion.Response{status_code: 200, body: "{\"status\": \"created\"}"}
      end do
      m = %Message{to: "me", msg: "Warning"}

      assert capture_log(fn ->
               {:noreply, _} = FourSixElksSender.handle_cast(m, nil)
             end) =~ "Successfully sent message"
    end

    test_with_mock "error status from remote", HTTPotion,
      post: fn _url, _data ->
        %HTTPotion.Response{status_code: 200, body: "{\"status\": \"error\"}"}
      end do
      m = %Message{to: "me", msg: "Warning"}

      assert capture_log(fn ->
               {:noreply, _} = FourSixElksSender.handle_cast(m, nil)
             end) =~ "Failed to send"
    end

    test_with_mock "non 200 response code", HTTPotion,
      post: fn _url, _data ->
        %HTTPotion.Response{status_code: 500, body: ""}
      end do
      m = %Message{to: "me", msg: "Warning"}

      assert capture_log(fn ->
               {:noreply, _} = FourSixElksSender.handle_cast(m, nil)
             end) =~ "Failed to send"
    end
  end
end
