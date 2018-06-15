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

    test "refutest non valid url" do
      changeset = Check.changeset(%Check{}, Map.put(@valid_attrs, :url, "invalid"))
      refute changeset.valid?
    end

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
      expected = Check.changeset(build_assoc(user, :checks), @valid_attrs) |> Repo.insert!()
      Check.changeset(build_assoc(other_user, :checks), @valid_attrs) |> Repo.insert!()

      [^expected] = Check.get_all(user.id)
    end

    test "get empty set" do
      {:ok, user, _token} = insert_user()
      [] = Check.get_all(user.id)
    end
  end
end
