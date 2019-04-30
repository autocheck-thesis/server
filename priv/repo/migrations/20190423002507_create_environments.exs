defmodule Thesis.Repo.Migrations.CreateEnvironments do
  use Ecto.Migration

  def change do
    create table(:environments) do
      add :name, :string
      add :dsl, :string

      timestamps()
    end

    create unique_index(:environments, [:name])
  end
end
