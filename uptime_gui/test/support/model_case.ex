defmodule UptimeGui.ModelCase do
  @moduledoc """
  This module defines the test case to be used by
  model tests.
  You may define functions here to be used as helpers in
  your model tests. See `errors_on/2`'s definition as reference.
  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias UptimeGui.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import UptimeGui.ModelCase
      import UptimeGui.Factories
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(UptimeGui.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(UptimeGui.Repo, {:shared, self()})
    end

    :ok
  end

  def errors_on(struct, data) do
    struct.__struct__.changeset(struct, data)
    |> Ecto.Changeset.traverse_errors(&UptimeGuiWeb.ErrorHelpers.translate_error/1)
    |> Enum.flat_map(fn {key, errors} -> for msg <- errors, do: {key, msg} end)
  end
end
