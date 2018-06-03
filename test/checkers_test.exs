defmodule CheckersTest do
  use ExUnit.Case, async: true

  alias Uptime.{Checkers, Check}

  describe "add_check/1" do
    test "add check and get pid" do
      check =
        %Check{url: "https://google.com"}
        |> Checkers.add_check()

      assert Process.alive?(check.pid)
    end
  end

  describe "remove_check/1" do
    check =
      %Check{url: "https://google.com"}
      |> Checkers.add_check()
      |> Checkers.remove_check()

    assert is_nil(check.pid)
  end
end
