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

  def token_data(token) do
    case Cipher.parse(token) do
      {:ok, token_data} ->
        {:ok, token_data}

      {:error, _} ->
        {:error, "Invalid token"}
    end
  end

  def authenticate(user_id, credentials) do
    case validate_credentials(credentials) do
      {:ok, true, user = %__MODULE__{id: ^user_id}} ->
        token =
          Cipher.cipher(%{
            "created" => DateTime.utc_now(),
            "user_id" => user.id
          })

        {:ok, token}

      _ ->
        {:error, "Invalid credentials"}
    end
  end

  def validate_credentials(provided) do
    case Repo.get_by(__MODULE__, email: provided.email) do
      user = %__MODULE__{} ->
        if Argon2.verify_pass(provided.password, user.password) do
          {:ok, true, user}
        else
          {:error, false, %{}}
        end

      nil ->
        {:error, Argon2.verify_pass("", @dummy_hash), %{}}
    end
  end
end
