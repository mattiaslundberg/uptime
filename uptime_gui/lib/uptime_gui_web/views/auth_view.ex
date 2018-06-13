defmodule UptimeGuiWeb.AuthView do
  def render("login.json", %{token: token, user_id: user_id}),
    do: %{"token" => token, "user_id" => user_id}

  def render("login.json", %{error: error}), do: %{"error" => error}
end
