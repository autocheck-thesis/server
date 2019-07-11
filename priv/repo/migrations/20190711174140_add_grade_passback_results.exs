defmodule Autocheck.Repo.Migrations.AddGradePassbackResults do
  use Ecto.Migration

  import Honeydew.EctoPollQueue.Migration

  def change do
    create table(:grade_passback_results, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:job_id, references(:jobs, type: :uuid))

      timestamps()

      honeydew_fields(:grade_passback)
    end

    honeydew_indexes(:grade_passback_results, :grade_passback)
  end
end
