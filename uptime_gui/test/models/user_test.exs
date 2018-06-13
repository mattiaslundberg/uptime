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
      {:ok, user} = User.create(@valid_attrs)
      assert {:ok, true, user} == User.validate_credentials(@valid_attrs)
    end

    test "incorrect password" do
      {:ok, _user} = User.create(@valid_attrs)

      {:error, false, _} =
        User.validate_credentials(Map.put(@valid_attrs, :password, "incorrect"))
    end

    test "non existing user" do
      {:error, false, _} = User.validate_credentials(%User{email: "asdf", password: ""})
    end
  end

  describe "authenticate/1" do
    test "correct credentials" do
      {:ok, user} = User.create(@valid_attrs)
      {:ok, ^user, _token} = User.authenticate(@valid_attrs)
    end

    test "incorrect credentials" do
      {:ok, _user} = User.create(@valid_attrs)
      {:error, _} = User.authenticate(Map.put(@valid_attrs, :password, "incorrect"))
    end
  end

  describe "token_data/1" do
    test "valid token" do
      {:ok, user = %User{id: user_id}} = User.create(@valid_attrs)
      {:ok, ^user, token} = User.authenticate(@valid_attrs)
      {:ok, %{"user_id" => ^user_id}} = User.token_data(token)
    end

    test "invalid token" do
      {:error, _} = User.token_data("haxxor")
    end
  end
end
