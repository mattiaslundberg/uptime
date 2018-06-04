defmodule UptimeGui.Repo.Migrations.CreateChecks do
  use Ecto.Migration

  def change do
    create table(:checks) do
      add :url, :text
      add :notify_number, :text
      add :expected_code, :integer

      timestamps()
    end

  end
end
