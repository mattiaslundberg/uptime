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

      {:ok, socket: socket, user: user}
    end

    test "create check with valid parameters", %{socket: socket} do
      ref = push(socket, "create_check", @valid_attrs)
      :timer.sleep(100)

      [%Check{id: check_id}] = Repo.all(Check)

      assert_reply(ref, :ok, %{
        "status_msg" => "Successfully created new check",
        "check_id" => ^check_id
      })
    end

    test "create check with invalid parameters", %{socket: socket} do
      invalid_attrs = Map.put(@valid_attrs, "url", "invalid")
      ref = push(socket, "create_check", invalid_attrs)
      :timer.sleep(100)

      [] = Repo.all(Check)

      assert_reply(ref, :error, %{"errors" => %{"url" => "Invalid format"}})
    end

    test "update existing check with valid parameters", %{socket: socket, user: user} do
      {:ok, %Check{id: check_id}} = insert_check(user)

      params = %{
        "id" => check_id,
        "url" => "https://new.example.com"
      }

      ref = push(socket, "update_check", params)

      assert_reply(ref, :ok, %{
        "status_msg" => "Successfully updated check",
        "check_id" => ^check_id
      })

      %Check{url: "https://new.example.com"} = Repo.get(Check, check_id)
    end

    test "update existing check with invalid parameters", %{socket: socket, user: user} do
      {:ok, check} = insert_check(user)

      params = %{
        "id" => check.id,
        "url" => "invalid"
      }

      ref = push(socket, "update_check", params)

      assert_reply(ref, :error, %{
        "errors" => %{"url" => "Invalid format"},
        "status_msg" => "Something went wrong when updating check"
      })
    end

    test "update check owned by other user", %{socket: socket} do
      {:ok, other_user, _token} = insert_user(email: "other@example.com")
      {:ok, check} = insert_check(other_user)

      params = %{
        "id" => check.id,
        "url" => "https://new.example.com"
      }

      ref = push(socket, "update_check", params)

      assert_reply(ref, :error, %{
        "status_msg" => "Cannot update non existing check",
        "errors" => %{}
      })
    end

    test "update non-existing check", %{socket: socket} do
      params = %{
        "id" => 3,
        "url" => "https://new.example.com"
      }

      ref = push(socket, "update_check", params)

      assert_reply(ref, :error, %{
        "status_msg" => "Cannot update non existing check",
        "errors" => %{}
      })
    end

    test "update check without sending id", %{socket: socket} do
      params = %{
        "url" => "https://new.example.com"
      }

      ref = push(socket, "update_check", params)

      assert_reply(ref, :error, %{
        "status_msg" => "Cannot update non existing check",
        "errors" => %{}
      })
    end

    test "remove existing check", %{socket: socket, user: user} do
      {:ok, check} = insert_check(user)

      ref = push(socket, "remove_check", %{"id" => check.id})
      assert_reply(ref, :ok, %{})

      assert is_nil(Repo.get(Check, check.id))
    end

    test "remove check that belongs to other user", %{socket: socket} do
      {:ok, other_user, _token} = insert_user(email: "hello@example.com")
      {:ok, check} = insert_check(other_user)
      ref = push(socket, "remove_check", %{"id" => check.id})

      assert_reply(ref, :error, %{
        "errors" => %{},
        "status_msg" => "Cannot remove non existing check"
      })

      assert not is_nil(Repo.get(Check, check.id))
    end

    test "remove non-existing check", %{socket: socket} do
      ref = push(socket, "remove_check", %{"id" => 3})

      assert_reply(ref, :error, %{
        "status_msg" => "Cannot remove non existing check",
        "errors" => %{}
      })
    end

    test "remove check without sending id", %{socket: socket} do
      ref = push(socket, "remove_check", %{})

      assert_reply(ref, :error, %{
        "status_msg" => "Cannot remove non existing check",
        "errors" => %{}
      })
    end
  end
end
