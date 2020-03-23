defmodule Pxblog.RoleChecker do

  alias Pxblog.Role
  alias Pxblog.Repo

  def is_admin?(user) do
    (role = Repo.get(Role, user.role_id)) && role.admin
  end
end
