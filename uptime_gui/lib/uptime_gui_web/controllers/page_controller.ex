defmodule UptimeGuiWeb.PageController do
  use UptimeGuiWeb, :controller

  alias UptimeGui.Repo
  alias UptimeGui.Check

  def index(conn, _params) do
    checks = Check.get_all()
    changeset = Check.changeset(%Check{})

    conn
    |> assign(:changeset, changeset)
    |> assign(:checks, checks)
    |> render(:index)
  end

  def create(conn, _params = %{"check" => check_params}) do
    checks = Check.get_all()

    case Check.create(check_params) do
      {:ok, check} ->
        conn
        |> put_status(:accepted)
        |> redirect(to: "/")

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> assign(:checks, checks)
        |> render(:index)
    end
  end
end
