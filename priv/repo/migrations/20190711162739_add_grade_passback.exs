defmodule Autocheck.Repo.Migrations.AddGradePassback do
  use Ecto.Migration

  def change do
    create table(:grade_passback, primary_key: false) do
      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all))
      add(:assignment_id, references(:assignments, type: :binary_id, on_delete: :delete_all))
      add(:lis_result_sourcedid, :text)
      add(:lis_outcome_service_url, :text)
    end
  end
end
