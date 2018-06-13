defmodule UptimeGuiWeb.PageController do
  use UptimeGuiWeb, :controller

  alias UptimeGui.Repo
  alias UptimeGui.Check

  def index(conn, _params) do
    render(conn, :index)
  end
end
