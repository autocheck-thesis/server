defmodule Thesis.Repo.Migrations.CreateSteps do
  use Ecto.Migration

  def change do
    create table(:steps, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string)
      add(:commands, {:array, :string})
      add(:configuration_id, references(:configurations, type: :binary_id))

      timestamps()
    end

    create(index(:steps, [:configuration_id]))
  end
end
