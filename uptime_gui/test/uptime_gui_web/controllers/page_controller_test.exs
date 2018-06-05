defmodule UptimeGuiWeb.PageControllerTest do
  use UptimeGuiWeb.ConnCase, async: false

  alias UptimeGui.{Repo, Check}

  @valid_attrs %{
    url: "https://example.com",
    notify_number: "+461234567",
    expected_code: 200
  }

  describe "index/2" do
    test "get", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "html"
    end
  end
end
