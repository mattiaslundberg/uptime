defmodule FourSixElksSenderTest do
  use ExUnit.Case
  alias Uptime.FourSixElksSender
  alias Uptime.Message
  import Mock

  test "sends message" do
    with_mock HTTPotion, post: fn _url, _data -> {:ok, "{\"status\": \"ok\"}"} end do
      m = %Message{to: "me", msg: "Warning"}
      FourSixElksSender.send_message(m)

      assert called(
               HTTPotion.post(
                 "https://api.46elks.com/a1/SMS",
                 body: Message.post_data(m),
                 ibrowse: []
               )
             )
    end
  end
end
