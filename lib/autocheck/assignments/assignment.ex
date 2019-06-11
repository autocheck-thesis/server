defmodule Autocheck.Assignments.Assignment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Autocheck.Assignments.Configuration
  alias Autocheck.Submissions.Submission

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "assignments" do
    field(:name, :string)
    has_many(:submissions, Submission)
    has_many(:configurations, Configuration)

    timestamps()
  end

  @doc false
  def changeset(assignment, attrs \\ %{}) do
    assignment
    |> cast(attrs, [:id, :name])
    |> cast_assoc(:configurations)
    |> validate_required([:id, :name])
  end
end
