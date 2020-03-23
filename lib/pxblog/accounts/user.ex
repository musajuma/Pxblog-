defmodule Pxblog.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  # import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field :email, :string
    field :password_digest, :string #virtual fields
    field :username, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    has_many :posts, Pxblog.Posts.Post
    belongs_to :role, Pxblog.Role


    timestamps()
  end

  @doc false
  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:username, :email, :password, :password_confirmation, :role_id])
    |> validate_required([:username, :email, :password, :password_confirmation, :role_id])
    |> hash_password()
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_digest, Bcrypt.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end
end
