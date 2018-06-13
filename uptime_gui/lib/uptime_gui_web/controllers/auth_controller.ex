defmodule UptimeGuiWeb.AuthController do
  use UptimeGuiWeb, :controller

  alias UptimeGui.User

  def index(conn, _params = %{"email" => email, "password" => password}) do
    case User.authenticate(%{email: email, password: password}) do
      {:ok, user, token} ->
        render(conn, "login.json", token: token, user_id: user.id)

      {:error, _} ->
        render(conn, "login.json", error: "Invalid credentials")
    end
  end
end
