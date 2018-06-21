defmodule UptimeGui.ContactTest do
  use UptimeGui.ModelCase, async: false

  alias UptimeGui.Contact

  @valid_attrs %{
    name: "My phone",
    number: "+461234567"
  }

  describe "validation" do
    test "refutes empty name" do
      changeset = Contact.changeset(%Contact{}, Map.put(@valid_attrs, :name, ""))
      refute changeset.valid?
    end

    test "valid data" do
      changeset = Contact.changeset(%Contact{}, @valid_attrs)
      assert changeset.valid?
    end
  end
end
