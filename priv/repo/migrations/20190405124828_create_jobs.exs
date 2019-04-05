defmodule Thesis.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:image, :string)
      add(:cmd, :string)

      timestamps
    end

    create table(:finished_jobs, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      timestamps
    end
  end
end
