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
    {:ok, user, token} = insert_user()
    {:ok, c} = insert_check(user)

    {:ok, _, _socket} =
      socket("user_id", %{some: :assign})
      |> subscribe_and_join(CheckChannel, "checks:" <> to_string(user.id), %{"token" => token})

    expected = Check.serialize(c)
    assert_push("create_check", ^expected)
  end

  describe "handle_in/3" do
    setup do
      {:ok, user, token} = insert_user()

      {:ok, _, socket} =
        socket("user_id", %{some: :assign})
        |> subscribe_and_join(CheckChannel, "checks:" <> to_string(user.id), %{"token" => token})

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

      assert_reply(ref, :error, %{"url" => "Invalid format"})
    end

    test "update existing check with valid parameters", %{socket: socket} do
      {:ok, check} = insert_check()

      params = %{
        "id" => check.id,
        "url" => "https://new.example.com"
      }

      ref = push(socket, "update_check", params)
      expected = Check.serialize(Map.put(check, :url, "https://new.example.com"))
      assert_reply(ref, :ok, ^expected)

      %Check{url: "https://new.example.com"} = Repo.get(Check, check.id)
    end

    test "update existing check with invalid parameters", %{socket: socket} do
      {:ok, check} = insert_check()

      params = %{
        "id" => check.id,
        "url" => "invalid"
      }

      ref = push(socket, "update_check", params)

      assert_reply(ref, :error, %{"url" => "Invalid format"})
    end

    test "update non-existing check", %{socket: socket} do
      params = %{
        "id" => 3,
        "url" => "https://new.example.com"
      }

      ref = push(socket, "update_check", params)

      expected = %{"msg" => "Check not found"}

      assert_reply(ref, :error, ^expected)
    end

    test "update check without sending id", %{socket: socket} do
      params = %{
        "url" => "https://new.example.com"
      }

      ref = push(socket, "update_check", params)

      expected = %{"msg" => "Check not found"}

      assert_reply(ref, :error, ^expected)
    end

    test "remove existing check", %{socket: socket} do
      {:ok, check} = insert_check()

      ref = push(socket, "remove_check", %{"id" => check.id})
      assert_reply(ref, :ok, %{})

      assert is_nil(Repo.get(Check, check.id))
    end

    test "remove non-existing check", %{socket: socket} do
      ref = push(socket, "remove_check", %{"id" => 3})
      assert_reply(ref, :error, %{"msg" => "Check not found"})
    end

    test "remove check without sending id", %{socket: socket} do
      ref = push(socket, "remove_check", %{})
      assert_reply(ref, :error, %{"msg" => "Check not found"})
    end
  end
end
