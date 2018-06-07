defmodule UptimeGui.UserTest do
  use UptimeGui.ModelCase, async: false

  alias UptimeGui.{User}

  @valid_attrs %{
    email: "test@example.com",
    password: "secret"
  }

  describe "create/1" do
    test "creates and hashes password" do
      {:ok, user} = User.create(@valid_attrs)

      %User{password: password} = Repo.get(User, user.id)
      refute password =~ "secret"
      assert password =~ "argon2"
    end
  end

  describe "validate_credentials/1" do
    test "correct credentials" do
      {:ok, _user} = User.create(@valid_attrs)
      assert User.validate_credentials(@valid_attrs)
    end

    test "incorrect password" do
      {:ok, _user} = User.create(@valid_attrs)
      refute User.validate_credentials(Map.put(@valid_attrs, :password, "incorrect"))
    end

    test "non existing user" do
      refute User.validate_credentials(%User{email: "asdf", password: ""})
    end
  end
end
