defmodule UptimeTest do
  use ExUnit.Case, async: false

  describe "add_new_check/5" do
    test "add new check" do
      check = Uptime.add_new_check("https://google.com", "+461234567", 200, nil, nil)
      assert Process.alive?(check.pid)
    end
  end
end
