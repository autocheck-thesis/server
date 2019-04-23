defmodule Thesis.Configuration do
  use Ecto.Schema
  import Ecto.Changeset

  schema "configurations" do
    field :dsl, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, [:name, :dsl])
    |> validate_required([:name, :dsl])
    |> unique_constraint(:name)
  end
end
