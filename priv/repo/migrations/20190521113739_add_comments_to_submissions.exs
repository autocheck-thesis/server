defmodule Thesis.Repo.Migrations.AddCommentsToSubmissions do
  use Ecto.Migration

  def change do
    alter table(:submissions) do
      add(:comment, :text)
    end
  end
end
