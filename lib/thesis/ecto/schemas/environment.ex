defmodule Thesis.Environment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "environments" do
    field :dsl, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(environment, attrs) do
    environment
    |> cast(attrs, [:name, :dsl])
    |> validate_required([:name, :dsl])
    |> unique_constraint(:name)
  end
end
