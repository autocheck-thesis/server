defmodule Autocheck.Submissions.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Autocheck.Accounts.{User}
  alias Autocheck.Assignments.Assignment
  alias Autocheck.Submissions.{File, Job}

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
