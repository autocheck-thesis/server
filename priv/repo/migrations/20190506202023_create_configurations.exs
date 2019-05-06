defmodule Thesis.Repo.Migrations.CreateConfigurations do
  use Ecto.Migration

  def change do
    create table(:configurations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:environment, :string)
      add(:image, :string)
      add(:required_files, {:array, :string})
      add(:assignment_id, references(:assignments, type: :binary_id))

      timestamps()
    end

    create(index(:configurations, [:assignment_id]))
  end
end
