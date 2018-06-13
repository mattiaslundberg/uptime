defmodule UptimeGuiWeb.AuthView do
  def render("login.json", %{token: token}), do: %{"token" => token}

  def render("login.json", %{error: error}), do: %{"error" => error}
end
