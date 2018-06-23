defmodule UptimeGui.CheckTest do
  use UptimeGui.ModelCase, async: false

  alias UptimeGui.Check

  @valid_attrs %{
    url: "https://example.com",
    notify_number: "+461234567",
    expected_code: 200
  }

  describe "validation" do
    setup do
      {:ok, user, _token} = insert_user()
      check = build_assoc(user, :checks)
      {:ok, check: check}
    end

    test "refutes empty url", %{check: check} do
      changeset = Check.changeset(check, Map.put(@valid_attrs, :url, ""))
      refute changeset.valid?
    end

    test "refutest non valid url", %{check: check} do
      changeset = Check.changeset(check, Map.put(@valid_attrs, :url, "invalid"))
      refute changeset.valid?
    end

    test "refutes empty code", %{check: check} do
      changeset = Check.changeset(check, Map.put(@valid_attrs, :expected_code, ""))
      refute changeset.valid?
    end

    test "valid data", %{check: check} do
      changeset = Check.changeset(check, @valid_attrs)
      assert changeset.valid?
    end
  end

  describe "create/3" do
    setup do
      {:ok, user, _token} = insert_user()
      {:ok, user: user}
    end

    test "create with 2 contacts", %{user: user} do
      {:ok, contact1} = insert_contact(user, number: "1")
      {:ok, contact2} = insert_contact(user, number: "2")

      {:ok, c = %Check{}, %Uptime.Check{pid: pid, url: url, notify_numbers: numbers}} =
        Check.create(user, [contact1, contact2], Map.delete(@valid_attrs, :notify_number))

      assert Process.alive?(pid)
      assert url == "https://example.com"
      assert numbers == ["1", "2"]

      assert length(c.contacts) == 2
    end

    test "create with single contact", %{user: user} do
      {:ok, contact} = insert_contact(user)

      {:ok, c = %Check{}, %Uptime.Check{pid: pid, url: url, notify_numbers: numbers}} =
        Check.create(user, [contact], Map.delete(@valid_attrs, :notify_number))

      assert Process.alive?(pid)
      assert url == "https://example.com"
      assert numbers == ["+461234567"]
      assert length(c.contacts) == 1
    end

    test "create without contacts", %{user: user} do
      {:ok, %Check{}, %Uptime.Check{pid: pid, url: url, notify_numbers: numbers}} =
        Check.create(user, [], Map.delete(@valid_attrs, :notify_number))

      assert Process.alive?(pid)
      assert url == "https://example.com"
      assert numbers == []
    end

    test "create with invalid params", %{user: user} do
      {:error, _} = Check.create(user, Map.delete(@valid_attrs, :url))
    end
  end

  describe "get_all/1" do
    test "get one" do
      {:ok, user, _token} = insert_user()
      Check.changeset(build_assoc(user, :checks), @valid_attrs) |> Repo.insert!()

      [%Check{}] = Check.get_all(user.id)
    end

    test "get two" do
      {:ok, user, _token} = insert_user()
      Check.changeset(build_assoc(user, :checks), @valid_attrs) |> Repo.insert!()
      Check.changeset(build_assoc(user, :checks), @valid_attrs) |> Repo.insert!()

      [%Check{}, %Check{}] = Check.get_all(user.id)
    end

    test "not getting other users" do
      {:ok, user, _token} = insert_user()
      {:ok, other_user, _token} = insert_user(email: "other@example.com")

      %Check{id: expected} =
        Check.changeset(build_assoc(user, :checks), @valid_attrs) |> Repo.insert!()

      Check.changeset(build_assoc(other_user, :checks), @valid_attrs) |> Repo.insert!()

      [%Check{id: ^expected}] = Check.get_all(user.id)
    end

    test "get empty set" do
      {:ok, user, _token} = insert_user()
      [] = Check.get_all(user.id)
    end
  end
end
