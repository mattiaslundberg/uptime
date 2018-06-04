defmodule MessageTest do
  use ExUnit.Case, async: false
  alias Uptime.Message

  describe "post_data" do
    test "get encoded data correctly" do
      m = %Message{
        to: "+461111111",
        msg: "Warning: it's down"
      }

      assert Message.post_data(m) == "from=Uptime&message=Warning%3A+it%27s+down&to=%2B461111111"
    end
  end
end
