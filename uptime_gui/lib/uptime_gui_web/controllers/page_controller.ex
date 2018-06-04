defmodule UptimeGuiWeb.PageController do
  use UptimeGuiWeb, :controller

  alias UptimeGui.Repo
  alias UptimeGui.Check

  def index(conn, _params) do
    checks = Check.get_all()

    conn
    |> assign(:checks, checks)
    |> render(:index)
  end
end
