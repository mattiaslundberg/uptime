defmodule UptimeGuiWeb.AuthController do
  use UptimeGuiWeb, :controller
  alias UptimeGui.User

  def login(conn, _params = %{"email" => email, "password" => password}) do
    case User.authenticate(%{email: email, password: password}) do
      {:ok, token} ->
        render(conn, "login.json", token: token)

      {:error, _} ->
        render(conn, "login.json", error: "Invalid credentials")
    end
  end
end
