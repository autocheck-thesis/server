defmodule Thesis.Assignment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "assignments" do
    field(:name, :string)
    has_many(:submissions, Thesis.Submission)

    timestamps()
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:id, :name])
    |> validate_required([:id, :name])
  end
end
