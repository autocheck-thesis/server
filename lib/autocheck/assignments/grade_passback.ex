defmodule Autocheck.Assignments.GradePassback do
  use Ecto.Schema
  import Ecto.Changeset

  alias Autocheck.Accounts.User
  alias Autocheck.Assignments.Assignment

  @primary_key false
  @foreign_key_type :binary_id

  schema "grade_passback" do
    belongs_to(:user, User)
    belongs_to(:assignment, Assignment)
    field(:lis_result_sourcedid, :string)
    field(:lis_outcome_service_url, :string)
  end

  @doc false
  def changeset(grade_passback, attrs \\ %{}) do
    grade_passback
    |> cast(attrs, [:lis_result_sourcedid, :lis_outcome_service_url])
    |> validate_required([:lis_result_sourcedid, :lis_outcome_service_url])
  end
end
