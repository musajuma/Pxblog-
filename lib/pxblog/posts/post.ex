defmodule Pxblog.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :body, :string
    field :title, :string
    belongs_to :user, Pxblog.Accounts.User
    has_many :comments, Pxblog.Comment

    timestamps()
  end

  @doc false
  def changeset(post, attrs \\ %{}) do
    post
    |> cast(attrs, [:title, :body])
    |> validate_required([:title, :body])
    |> strip_unsafe_body(attrs)
  end

  defp strip_unsafe_body(model, %{"body" => nil}) do
    model
  end

  defp strip_unsafe_body(model, %{"body" => body}) do
    {:safe, clean_body} = Phoenix.HTML.html_escape(body)
    model |> put_change(:body, clean_body)
  end

  defp strip_unsafe_body(model, _) do
    model
  end
end
