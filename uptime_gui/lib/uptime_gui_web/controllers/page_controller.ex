defmodule UptimeGuiWeb.PageController do
  use UptimeGuiWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
