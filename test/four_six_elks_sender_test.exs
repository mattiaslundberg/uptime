defmodule FourSixElksSenderTest do
  use ExUnit.Case, async: false

  alias Uptime.FourSixElksSender
  alias Uptime.Message

  require Logger

  import ExUnit.CaptureLog
  import Mock

  describe "send_message/1" do
    test "sends successful response" do
      assert capture_log(fn ->
               with_mock HTTPotion,
                 post: fn _url, _data ->
                   %HTTPotion.Response{status_code: 200, body: "{\"status\": \"created\"}"}
                 end do
                 m = %Message{to: "me", msg: "Warning"}
                 FourSixElksSender.send_message(m)

                 assert called(
                          HTTPotion.post(
                            "https://api.46elks.com/a1/SMS",
                            body: Message.post_data(m),
                            ibrowse: [basic_auth: {'testuser', 'secret'}]
                          )
                        )
               end
             end) =~ "Successfully sent message"
    end
  end

  describe "handle_cast/2" do
    test "successful response" do
      with_mock HTTPotion,
        post: fn _url, _data ->
          %HTTPotion.Response{status_code: 200, body: "{\"status\": \"created\"}"}
        end do
        m = %Message{to: "me", msg: "Warning"}

        assert capture_log(fn ->
                 {:noreply, _} = FourSixElksSender.handle_cast(m, nil)
               end) =~ "Successfully sent message"
      end
    end

    test "error status from remote" do
      with_mock HTTPotion,
        post: fn _url, _data ->
          %HTTPotion.Response{status_code: 200, body: "{\"status\": \"error\"}"}
        end do
        m = %Message{to: "me", msg: "Warning"}

        assert capture_log(fn ->
                 {:noreply, _} = FourSixElksSender.handle_cast(m, nil)
               end) =~ "Failed to send"
      end
    end

    test "non 200 response code" do
      with_mock HTTPotion,
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
end
