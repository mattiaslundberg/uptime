defmodule UptimeGuiWeb.CheckChannelTest do
  use UptimeGuiWeb.ChannelCase

  alias UptimeGuiWeb.CheckChannel
  alias UptimeGui.{Check, Repo}

  @valid_attrs %{
    "url" => "https://example.com",
    "notify_number" => "+461234567",
    "expected_code" => 200
  }

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

    test "create check with valid parameters", %{socket: socket} do
      ref = push(socket, "create_check", @valid_attrs)
      :timer.sleep(100)

      [%Check{id: check_id}] = Repo.all(Check)
      expected = Map.put(@valid_attrs, "id", check_id)
      assert_reply(ref, :ok, ^expected)
    end

    test "create check with invalid parameters", %{socket: socket} do
      invalid_attrs = Map.put(@valid_attrs, "url", "invalid")
      ref = push(socket, "create_check", invalid_attrs)
      :timer.sleep(100)

      [] = Repo.all(Check)
      assert_reply(ref, :error, %{})
    end

    # test "update existing check with valid parameters"
    # test "update existing check with invalid parameters"
    # test "update non-existing check"
    # test "remove existing check"
    # test "remove non-existing check"

    # test "ping replies with status ok", %{socket: socket} do
    #   ref = push(socket, "ping", %{"hello" => "there"})
    #   assert_reply(ref, :ok, %{"hello" => "there"})
    # end

    # test "shout broadcasts to check:lobby", %{socket: socket} do
    #   push(socket, "shout", %{"hello" => "all"})
    #   assert_broadcast("shout", %{"hello" => "all"})
    # end

    # test "broadcasts are pushed to the client", %{socket: socket} do
    #   broadcast_from!(socket, "broadcast", %{"some" => "data"})
    #   assert_push("broadcast", %{"some" => "data"})
    # end
  end
end
