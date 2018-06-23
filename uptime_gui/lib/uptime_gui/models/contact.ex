defmodule UptimeGui.Contact do
  use UptimeGuiWeb, :schema
  import Ecto.Changeset

  alias UptimeGui.Repo

  schema "contacts" do
    field(:name, :string)
    field(:number, :string)

    belongs_to(:user, UptimeGui.User)

    many_to_many(:checks, UptimeGui.Check, join_through: "checks_contacts")

    timestamps()
  end

  def serialize(contact) do
    %{
      "id" => contact.id,
      "name" => contact.name,
      "number" => contact.number
    }
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :number, :user_id])
    |> validate_required([:name, :number, :user_id])
  end

  def create(user, params) do
    user
    |> Ecto.build_assoc(:contacts)
    |> changeset(params)
    |> Repo.insert()
  end

  def get_list(user_id, ids) do
    __MODULE__
    |> where([c], c.user_id == ^user_id and c.id in ^ids)
    |> Repo.all()
  end
end
