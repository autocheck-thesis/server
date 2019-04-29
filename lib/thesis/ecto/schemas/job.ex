defmodule Thesis.Job do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "jobs" do
    field(:image, :string)
    field(:cmd, :string)
    field(:finished, :boolean, default: false)
    belongs_to(:submission, Thesis.Submission)

    timestamps()
  end

  @required_fields [:image, :cmd]

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> cast_assoc(:submission)
  end

  def finish(job) do
    job |> change(finished: true)
  end
end
