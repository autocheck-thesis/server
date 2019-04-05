defmodule Thesis.Repo.Migrations.CreateSubmissions do
  use Ecto.Migration

  def change do
    create table(:submissions, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:author_id, references(:users, type: :uuid))
      add(:assignment_id, :string)
      add(:assignment_name, :string)

      timestamps()
    end
  end
end
