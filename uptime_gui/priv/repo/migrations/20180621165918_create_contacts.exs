defmodule UptimeGui.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add(:name, :string, null: false)
      add(:number, :string, null: false)

      timestamps()
    end
  end
end
