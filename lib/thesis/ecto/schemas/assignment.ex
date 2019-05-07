defmodule Thesis.Assignment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "assignments" do
    field(:name, :string)
    has_many(:submissions, Thesis.Submission)
    has_many(:configuration, Thesis.Configuration)

    timestamps()
  end

  @doc false
  def changeset(assignment, attrs \\ %{}) do
    assignment
    |> cast(attrs, [:id, :name])
    |> cast_assoc(:configuration)
    |> validate_required([:id, :name])
  end
end
