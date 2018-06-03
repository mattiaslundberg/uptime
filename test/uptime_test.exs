defmodule UptimeTest do
  use ExUnit.Case
  doctest Uptime

  test "sends message" do
    assert Uptime.hello() == :world
  end
end
