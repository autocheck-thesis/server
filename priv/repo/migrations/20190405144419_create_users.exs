defmodule Thesis.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:lti_user_id, :string)

      timestamps()
    end

    create(index(:users, [:lti_user_id]))
  end
end
