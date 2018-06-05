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
end
