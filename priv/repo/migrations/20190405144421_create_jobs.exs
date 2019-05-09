defmodule Thesis.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  import Honeydew.EctoPollQueue.Migration

  def change do
    create table(:jobs, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:submission_id, references(:submissions, type: :uuid))
      add(:image, :string)
      add(:cmd, :text)
      add(:finished, :boolean)

      timestamps()

      honeydew_fields(:run_jobs)
    end

    honeydew_indexes(:jobs, :run_jobs)
  end
end
