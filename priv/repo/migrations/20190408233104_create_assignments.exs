defmodule Thesis.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments) do
      add :assignment_id, :string
      add :name, :string
      add :cmd, :string
      add :dsl, :string

      timestamps()
    end

  end
end
