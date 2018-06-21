defmodule UptimeGui.Repo.Migrations.CreateChecksContacts do
  use Ecto.Migration

  def change do
    create table(:checks_contacts) do
      add(:check_id, references(:checks))
      add(:contact_id, references(:contacts))
    end

    create(unique_index(:checks_contacts, [:check_id, :contact_id]))
  end
end
