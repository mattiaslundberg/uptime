defmodule UptimeGuiWeb.CheckChannelTest do
  use UptimeGuiWeb.ChannelCase

  alias UptimeGuiWeb.CheckChannel
  alias UptimeGui.Check

  test "sends checks after connection" do
    {:ok, c} = insert_check()

    {:ok, _, socket} =
      socket("user_id", %{some: :assign})
      |> subscribe_and_join(CheckChannel, "checks:2")

    expected = Check.serialize(c)
    assert_push("create_check", ^expected)
  end

  describe "handle_in/3" do
    setup do
      {:ok, _, socket} =
        socket("user_id", %{some: :assign})
        |> subscribe_and_join(CheckChannel, "checks:2")

      {:ok, socket: socket}
    end

    test "create check with valid parameters"
    test "create check with invalid parameters"
    test "update existing check with valid parameters"
    test "update existing check with invalid parameters"
    test "update non-existing check"
    test "remove existing check"
    test "remove non-existing check"
  end
end
