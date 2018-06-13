defmodule UptimeGui.Repo.Migrations.CheckBelongsToUser do
  use Ecto.Migration

  def change do
    alter table(:checks) do
      add(:user_id, references(:users))
    end
  end
end
