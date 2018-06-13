defmodule UptimeGuiWeb.AuthControllerTest do
  use UptimeGuiWeb.ConnCase, async: false

  describe "login/2" do
    test "login with valid credentials" do
      conn = build_conn()
      {:ok, user, _token} = insert_user(password: "secret")
      conn = post(conn, "/api/login", %{"email" => user.email, "password" => "secret"})

      assert Map.keys(json_response(conn, 200)) == ["token", "user_id"]
    end

    test "login with invalid password" do
      conn = build_conn()
      {:ok, user, _token} = insert_user(password: "secret")
      conn = post(conn, "/api/login", %{"email" => user.email, "password" => "invalid"})

      assert Map.keys(json_response(conn, 200)) == ["error"]
    end
  end
end
