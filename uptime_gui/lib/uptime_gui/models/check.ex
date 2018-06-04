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
  end

  def get_all() do
    Repo.all(__MODULE__)
  end
end
