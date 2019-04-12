defmodule Thesis.Repo.Migrations.CreateDownloadTokens do
  use Ecto.Migration

  def change do
    create table(:download_tokens, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:submission_id, references(:submissions, type: :uuid))

      timestamps()
    end
  end
end
