defmodule UptimeGui.Check do
  use UptimeGuiWeb, :schema

  alias UptimeGui.Repo

  schema "checks" do
    field(:url, :string)
    field(:notify_number, :string)
    field(:expected_code, :integer)

    belongs_to(:user, UptimeGui.User)

    many_to_many(:contacts, UptimeGui.Contact, join_through: "checks_contacts")

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :notify_number, :expected_code, :user_id])
    |> validate_required([:url, :notify_number, :expected_code, :user_id])
    |> validate_format(:url, ~r/https?\:\/\/.*/, message: "Invalid format")
  end

  def get_all(user_id) do
    __MODULE__
    |> where([c], c.user_id == ^user_id)
    |> Repo.all()
  end

  def get(user_id, check_id) do
    __MODULE__
    |> where([c], c.user_id == ^user_id and c.id == ^check_id)
    |> Repo.one()
  end

  def serialize(c = %__MODULE__{}) do
    %{
      "id" => c.id,
      "url" => c.url,
      "notify_number" => c.notify_number,
      "expected_code" => c.expected_code
    }
  end

  def create(user, contacts \\ [], params) do
    check_changeset = build_assoc(user, :checks) |> changeset(params)

    case Repo.insert(check_changeset) do
      {:ok, check} ->
        numbers = [check.notify_number | Enum.map(contacts, & &1.number)]

        pid =
          Uptime.add_new_check(
            check.url,
            numbers,
            check.expected_code,
            Application.get_env(:uptime_gui, :elks_username),
            Application.get_env(:uptime_gui, :elks_key)
          )

        {:ok, check, pid}

      r ->
        r
    end
  end
end
