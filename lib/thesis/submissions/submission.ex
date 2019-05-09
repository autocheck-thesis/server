defmodule Thesis.Submissions.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Thesis.Assignments.Assignment
  alias Thesis.Submissions.File

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "submissions" do
    belongs_to(:assignment, Assignment)
    belongs_to(:author, Thesis.User)
    has_many(:jobs, Thesis.Job)
    has_many(:files, File)

    timestamps()
  end

  @required_fields []

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> cast_assoc(:jobs)
    |> cast_assoc(:files)
  end
end