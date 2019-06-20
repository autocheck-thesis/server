defmodule Autocheck.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:assignment_files, primary_key: false) do
      add(:name, :text, primary_key: true)
      add(:contents, :binary)
      add(:assignment_id, references(:assignments, type: :uuid), primary_key: true)
    end

    create table(:submission_files, primary_key: false) do
      add(:name, :text, primary_key: true)
      add(:contents, :binary)
      add(:submission_id, references(:submissions, type: :uuid), primary_key: true)
    end
  end
end
