defmodule UptimeGui.Factories do
  alias UptimeGui.{Check, User, Repo, Contact}

  def insert_check(user, opts \\ []) do
    Check.changeset(
      Ecto.build_assoc(user, :checks),
      %{
        url: Keyword.get(opts, :url, "https://example.com"),
        notify_number: Keyword.get(opts, :notify_number, "+461234567"),
        expected_code: Keyword.get(opts, :expected_code, 200)
      }
    )
    |> Repo.insert()
  end

  def insert_contact(user, opts \\ []) do
    Contact.changeset(
      Ecto.build_assoc(user, :contacts),
      %{
        name: Keyword.get(opts, :name, "My number"),
        number: Keyword.get(opts, :number, "+461234567")
      }
    )
    |> Repo.insert()
  end

  def insert_user(opts \\ []) do
    password = Keyword.get(opts, :password, "password")

    {:ok, user} =
      User.changeset(%UptimeGui.User{}, %{
        email: Keyword.get(opts, :email, "test@example.com"),
        password: Argon2.hash_pwd_salt(password)
      })
      |> Repo.insert()

    User.authenticate(%{email: user.email, password: password})
  end
end
