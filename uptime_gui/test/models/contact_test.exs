defmodule UptimeGui.ContactTest do
  use UptimeGui.ModelCase, async: false

  alias UptimeGui.Contact

  @valid_attrs %{
    name: "My phone",
    number: "+461234567"
  }

  describe "validation" do
    setup do
      {:ok, user, _token} = insert_user()
      contact = build_assoc(user, :contacts)
      {:ok, contact: contact}
    end

    test "refutes empty name", %{contact: contact} do
      changeset = Contact.changeset(contact, Map.put(@valid_attrs, :name, ""))
      refute changeset.valid?
    end

    test "refutes missing name", %{contact: contact} do
      changeset = Contact.changeset(contact, Map.delete(@valid_attrs, :name))
      refute changeset.valid?
    end

    test "valid data", %{contact: contact} do
      changeset = Contact.changeset(contact, @valid_attrs)
      assert changeset.valid?
    end
  end
end
