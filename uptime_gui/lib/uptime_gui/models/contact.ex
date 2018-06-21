defmodule UptimeGui.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field(:name, :string)
    field(:number, :string)

    belongs_to(:user, UptimeGui.User)

    many_to_many(:checks, UptimeGui.Check, join_through: "checks_contacts")

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :number, :user_id])
    |> validate_required([:name, :number, :user_id])
  end
end
