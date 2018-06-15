defmodule UptimeGui.Factories do
  alias UptimeGui.{Check, User, Repo}

  def insert_check(user \\ nil, opts \\ []) do
    check =
      case user do
        nil -> %Check{}
        _ -> Ecto.build_assoc(user, :checks)
      end

    Check.changeset(
      check,
      %{
        url: Keyword.get(opts, :url, "https://example.com"),
        notify_number: Keyword.get(opts, :notify_number, "+461234567"),
        expected_code: Keyword.get(opts, :expected_code, 200)
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
