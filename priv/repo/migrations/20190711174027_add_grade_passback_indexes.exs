defmodule Autocheck.Repo.Migrations.AddGradePassbackIndexes do
  use Ecto.Migration

  def change do
    create(index(:grade_passback, [:user_id, :assignment_id], unique: true))
  end
end
