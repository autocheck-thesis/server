defmodule Thesis.Repo.Migrations.CreateConfigurations do
  use Ecto.Migration

  def change do
    create table(:configurations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:code, :text)
      add(:assignment_id, references(:assignments, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end

    create(index(:configurations, [:assignment_id]))
  end
end
