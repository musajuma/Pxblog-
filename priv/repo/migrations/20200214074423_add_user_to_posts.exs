defmodule Pxblog.Repo.Migrations.AddUserToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :user_id, references(:users)
    end

    create index(:posts, [:user_id])
  end
end
