defmodule UptimeGui.Factories do
  alias UptimeGui.Repo

  def insert_check(opts \\ []) do
    UptimeGui.Check.changeset(
      %UptimeGui.Check{},
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
      UptimeGui.User.changeset(%UptimeGui.User{}, %{
        email: Keyword.get(opts, :email, "test@example.com"),
        password: Argon2.hash_pwd_salt(password)
      })
      |> Repo.insert()

    {:ok, token} = UptimeGui.User.authenticate(%{email: user.email, password: password})
    {:ok, user, token}
  end
end
