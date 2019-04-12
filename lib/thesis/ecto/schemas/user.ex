defmodule Thesis.User do
  use Ecto.Schema
  import Ecto.Changeset

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field(:lti_user_id, :string)
    has_many(:submissions, {"author_id", Thesis.Submission})

    timestamps()
  end

  @required_fields [:lti_user_id]

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
  end
end
