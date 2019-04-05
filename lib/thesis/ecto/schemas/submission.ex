defmodule Thesis.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "submissions" do
    field(:assignment_id, :string)
    field(:assignment_name, :string)
    belongs_to(:author, Thesis.User)
    has_many(:jobs, Thesis.Job)

    timestamps()
  end

  @required_fields [:assignment_id, :assignment_name]

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
  end

  def create(assignment_id, assignment_name, author) do
    changeset(%__MODULE__{}, %{
      "assignment_id" => assignment_id,
      "assignment_name" => assignment_name
    })
    |> put_assoc(:author, author)
  end
end
