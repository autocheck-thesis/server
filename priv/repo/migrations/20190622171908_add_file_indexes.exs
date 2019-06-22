defmodule Autocheck.Repo.Migrations.AddFileIndexes do
  use Ecto.Migration

  def change do
    create(index(:assignment_files, [:assignment_id]))
    create(index(:submission_files, [:submission_id]))
  end
end
