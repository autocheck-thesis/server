defmodule Autocheck.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  import Honeydew.EctoPollQueue.Migration

  def change do
    create table(:jobs, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:submission_id, references(:submissions, type: :uuid))
      add(:download_token, :uuid, default: fragment("uuid_generate_v4()"))
      add(:finished, :boolean)

      timestamps()

      honeydew_fields(:run_jobs)
    end

    create(index(:jobs, [:download_token]))
    honeydew_indexes(:jobs, :run_jobs)
  end
end
