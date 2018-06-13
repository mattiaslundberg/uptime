defmodule UptimeGuiWeb.AuthControllerTest do
  use UptimeGuiWeb.ConnCase, async: false

  describe "login/2" do
    test "login with valid credentials", %{conn: conn} do
      {:ok, user, token} = insert_user(password: "secret")
      conn = post(conn, "/login", %{"email" => user.email, "password" => "secret"})

      assert Map.keys(json_response(conn, 200)) == ["token"]
    end

    test "login with invalid password" do
      {:ok, user, token} = insert_user(password: "secret")
      conn = post(conn, "/login", %{"email" => user.email, "password" => "invalid"})

      assert Map.keys(json_response(conn, 200)) == ["error"]
    end
  end
end
