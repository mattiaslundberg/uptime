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
    changeset = Check.changeset(%Check{}, check_params)

    case Repo.insert(changeset) do
      {:ok, check} ->
        # TODO: Get elks credentials from check?
        Uptime.add_new_check(
          check.url,
          check.notify_number,
          check.expected_code,
          Application.get_env(:uptime_gui, :elks_username),
          Application.get_env(:uptime_gui, :elks_key)
        )

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
