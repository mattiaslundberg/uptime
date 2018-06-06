defmodule UptimeGuiWeb.PageControllerTest do
  use UptimeGuiWeb.ConnCase, async: false

  describe "index/2" do
    test "get", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "html"
    end
  end
end
