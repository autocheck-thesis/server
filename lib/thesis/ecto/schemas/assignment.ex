defmodule Thesis.Assignment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assignments" do
    field :assignment_id, :string
    field :cmd, :string
    field :dsl, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:assignment_id, :name, :cmd, :dsl])
    |> validate_required([:assignment_id, :name, :cmd, :dsl])
  end
end
