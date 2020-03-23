defmodule PxblogWeb.SessionController do
  use PxblogWeb, :controller

  alias Pxblog.Accounts.User
  alias Pxblog.Repo

  plug :scrub_params, "user" when action in [:create]

  def new(conn, params) do
    render conn, "new.html", changeset: User.changeset(%User{}, params)
  end

  def create(conn, %{"user" => %{"username" => username, "password" => password}}) when not is_nil(username) and not is_nil(password) do
      user = Repo.get_by(User, username: username)
      sign_in(user, password, conn)
  end

  def create(conn, _) do
    failed_login(conn)
  end

  defp failed_login(conn) do
    Bcrypt.no_user_verify()
    conn
    |> put_session(:current_user, nil)
    |> put_flash(:error, "Invalid username/password combination")
    |> redirect(to: Routes.page_path(conn, :index))
    |> halt()
  end

  defp sign_in(user, _password, conn) when is_nil(user) do
    failed_login(conn)
  end

  defp sign_in(user, password, conn) do
    if Bcrypt.verify_pass(password, user.password_digest) do
      conn
      |> put_session(:current_user, %{id: user.id, username: user.username, role_id: user.role_id})
      |> put_flash(:info, "Sign in Successfull")
      |> redirect(to: Routes.page_path(conn, :index))
    else
      conn
      |> put_session(:current_user, nil)
      |> put_flash(:info, "Invalid username/password combination")
      |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:current_user)
    |> put_flash(:info, "Signed out successfull")
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
