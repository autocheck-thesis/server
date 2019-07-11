defmodule Autocheck.Assignments.GradePassbackResult do
  use Ecto.Schema
  import Ecto.Changeset
  import Honeydew.EctoPollQueue.Schema
  alias Autocheck.Submissions.Job

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "grade_passback_results" do
    belongs_to(:job, Job)

    timestamps()

    honeydew_fields(:grade_passback)
  end

  @doc false
  def changeset(grade_passback_result, attrs \\ %{}) do
    grade_passback_result
    |> cast(attrs, [])
    |> validate_required([])
  end
end
