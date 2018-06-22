defmodule UptimeGui.Repo.Migrations.RemoveNotifyNumber do
  use Ecto.Migration

  def change do
    alter table(:checks) do
      remove(:notify_number)
    end
  end
end
