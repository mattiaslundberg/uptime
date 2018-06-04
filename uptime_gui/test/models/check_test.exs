defmodule UptimeGui.CheckTest do
  use UptimeGui.ModelCase, async: false

  alias UptimeGui.Check

  @valid_attrs %{
    url: "https://example.com",
    notify_number: "+461234567",
    expected_code: 200
  }

  describe "validation" do
    test "refutes empty url" do
      changeset = Check.changeset(%Check{}, Map.put(@valid_attrs, :url, ""))
      refute changeset.valid?
    end

    test "refutest non valid url"

    test "refutes empty number" do
      changeset = Check.changeset(%Check{}, Map.put(@valid_attrs, :notify_number, ""))
      refute changeset.valid?
    end

    test "refutes empty code" do
      changeset = Check.changeset(%Check{}, Map.put(@valid_attrs, :expected_code, ""))
      refute changeset.valid?
    end

    test "valid data" do
      changeset = Check.changeset(%Check{}, @valid_attrs)
      assert changeset.valid?
    end
  end

  describe "helpers" do
    test "get_all/0" do
      Check.changeset(%Check{}, @valid_attrs) |> Repo.insert!()

      [%Check{}] = Check.get_all()
    end
  end
end
