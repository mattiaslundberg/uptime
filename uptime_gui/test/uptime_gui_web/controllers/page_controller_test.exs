defmodule UptimeGuiWeb.PageControllerTest do
  use UptimeGuiWeb.ConnCase, async: false

  alias UptimeGui.{Repo, Check}

  @valid_attrs %{
    url: "https://example.com",
    notify_number: "+461234567",
    expected_code: 200
  }

  describe "index/2" do
    test "empty list", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Active checks"
    end

    test "get urls from list", %{conn: conn} do
      Check.changeset(%Check{}, @valid_attrs) |> Repo.insert!()
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "https://example.com"
    end

    test "renders form", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Notify this number"
    end
  end

  describe "create/2" do
    test "post with valid data", %{conn: conn} do
      conn = post(conn, "/", %{"check" => @valid_attrs})
      assert html_response(conn, 202) =~ "redirected"
    end

    test "post with invalid data", %{conn: conn} do
      attrs = Map.put(@valid_attrs, :url, nil)
      conn = post(conn, "/", %{"check" => attrs})
      assert html_response(conn, 200) =~ "required"
    end
  end
end
