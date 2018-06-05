defmodule UptimeGui.Check do
  use UptimeGuiWeb, :schema

  alias UptimeGui.Repo

  schema "checks" do
    field(:url, :string)
    field(:notify_number, :string)
    field(:expected_code, :integer)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :notify_number, :expected_code])
    |> validate_required([:url, :notify_number, :expected_code])
    |> validate_format(:url, ~r/https?\:\/\/.*/)
  end

  def get_all() do
    Repo.all(__MODULE__)
  end

  def serialize(c = %__MODULE__{}) do
    %{
      "url" => c.url,
      "notify_number" => c.notify_number,
      "expected_code" => c.expected_code
    }
  end

  def create(params) do
    changeset = changeset(%__MODULE__{}, params)

    case Repo.insert(changeset) do
      {:ok, check} ->
        Uptime.add_new_check(
          check.url,
          check.notify_number,
          check.expected_code,
          Application.get_env(:uptime_gui, :elks_username),
          Application.get_env(:uptime_gui, :elks_key)
        )

        {:ok, check}

      r ->
        r
    end
  end
end
