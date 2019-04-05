defmodule Thesis.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:submission_id, references(:submissions, type: :uuid))
      add(:image, :string)
      add(:filename, :string)
      add(:cmd, :string)
      add(:finished, :boolean)

      timestamps()
    end
  end
end
