defmodule PxblogWeb.PostController do
  use PxblogWeb, :controller

  import Ecto
  import Ecto.Query

  alias Pxblog.Posts
  alias Pxblog.Posts.Post
  alias Pxblog.Repo
  alias Pxblog.Comment

  plug :assign_user when not action in [:index]
  plug :authorize_user when action in [:new, :create, :update, :edit, :delete]
  plug :set_authorization_flag

  def index(conn, %{"user_id" => _user_id}) do
    conn = assign_user(conn, nil)
    if conn.assigns[:user] do
      posts = Repo.all(assoc(conn.assigns[:user], :posts)) |> Repo.preload(:user)
      render(conn, "index.html", posts: posts)
    else
      conn
    end
  end

  def index(conn, _params) do
    posts = Repo.all(from p in Post,
                       limit: 5,
                       order_by: [desc: :inserted_at],
                       preload: [:user])
    render(conn, "index.html", posts: posts)
  end

  def new(conn, params) do
    changeset =
          conn.assigns[:user]
          |> build_assoc(:posts)
          |> Post.changeset(params)

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    changeset =
      conn.assigns[:user]
      |> build_assoc(:posts)
      |> Post.changeset(post_params)

    case Repo.insert(changeset) do
      {:ok, _post} ->
        conn
        |> put_flash(:info, "Post created successfully.")
        |> redirect(to: Routes.user_post_path(conn, :index, conn.assigns[:user]))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    post = Repo.get!(assoc(conn.assigns[:user], :posts), id)
    |> Repo.preload(:comments)

    comment_changeset = post
      |> build_assoc(:comments)
      |> Comment.changeset()
    render(conn, "show.html", post: post, comment_changeset: comment_changeset)
  end

  def edit(conn, %{"id" => id}) do
    post = Repo.get!(assoc(conn.assigns[:user], :posts), id)
    changeset = Posts.change_post(post)
    render(conn, "edit.html", post: post, changeset: changeset)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Repo.get!(assoc(conn.assigns[:user], :posts), id)
    changeset = Post.changeset(post, post_params)
    case Repo.update(changeset) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: Routes.user_post_path(conn, :show, conn.assigns[:user], post))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Repo.get!(assoc(conn.assigns[:user], :posts), id)
    Repo.delete!(post)
    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: Routes.user_post_path(conn, :index, conn.assigns[:user]))
  end

  defp assign_user(conn, _opts) do
    case conn.params do
      %{"user_id" => user_id} ->
        case Repo.get(Pxblog.Accounts.User, user_id) do
          nil -> invalid_user(conn)
          user -> assign(conn, :user, user)
        end
      _ -> invalid_user(conn)
    end
  end

  defp invalid_user(conn) do
    conn
    |> put_flash(:error, "Invalid user!")
    |> redirect(to: Routes.page_path(conn, :index))
    |> halt()
  end

  defp authorize_user(conn, _opts) do
    if is_authorized_user?(conn) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to modify that post!")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt
    end
  end

  defp is_authorized_user?(conn) do
    user = get_session(conn, :current_user)
    (user && (Integer.to_string(user.id) == conn.params["user_id"] || Pxblog.RoleChecker.is_admin?(user)))
  end

  defp set_authorization_flag(conn, _opts) do
    assign(conn, :author_or_admin, is_authorized_user?(conn))
  end

end
