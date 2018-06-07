defmodule UptimeGui.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias UptimeGui.Repo

  @dummy_hash "$argon2i$v=19$m=65536,t=6,p=1$LUuXCYxlIKebJCvS+NVctw$lpTjnzA2us0nSvOrFIi1XaJNttIXWzZUWNptTWUmlco"

  schema "users" do
    field(:email, :string)
    field(:password, :string)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
  end

  def create(params = %{password: password}) do
    params = Map.put(params, :password, Argon2.hash_pwd_salt(password))

    %__MODULE__{}
    |> changeset(params)
    |> Repo.insert()
  end

  def validate_credentials(provided) do
    case Repo.get_by(__MODULE__, email: provided.email) do
      user = %__MODULE__{} ->
        Argon2.verify_pass(provided.password, user.password)

      nil ->
        Argon2.verify_pass("", @dummy_hash)
    end
  end
end
