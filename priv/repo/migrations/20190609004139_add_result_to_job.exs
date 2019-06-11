defmodule Autocheck.Repo.Migrations.AddResultToJob do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add(:result, {:array, :map})
    end
  end
end
