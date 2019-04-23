defmodule Thesis.Repo.Migrations.CreateConfigurations do
  use Ecto.Migration

  def change do
    create table(:configurations) do
      add :name, :string
      add :dsl, :string

      timestamps()
    end

    create unique_index(:configurations, [:name])
  end
end
