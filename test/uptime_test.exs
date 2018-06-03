defmodule UptimeTest do
  use ExUnit.Case, async: false
  doctest Uptime

  test "sends message" do
    assert Uptime.hello() == :world
  end
end
