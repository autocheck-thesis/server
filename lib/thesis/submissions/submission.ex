defmodule Thesis.Submissions.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Thesis.Accounts.{User}
  alias Thesis.Assignments.Assignment
  alias Thesis.Submissions.{File, Job}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "submissions" do
    belongs_to(:assignment, Assignment)
    belongs_to(:author, User)
    has_many(:jobs, Job)
    has_many(:files, File)
    field(:comment, :string)

    timestamps()
  end

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:comment])
    |> cast_assoc(:jobs)
    |> cast_assoc(:files)
  end
end
