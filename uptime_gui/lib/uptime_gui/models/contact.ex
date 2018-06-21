defmodule UptimeGui.UptimeGui.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field(:name, :string)
    field(:number, :string)

    belongs_to(:user, UptimeGui.User)

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :number])
    |> validate_required([:name, :number])
  end
end
