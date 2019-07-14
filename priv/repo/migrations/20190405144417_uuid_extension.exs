defmodule Autocheck.Repo.Migrations.UuidExtension do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";")
  end
end
