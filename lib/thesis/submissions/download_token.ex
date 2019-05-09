defmodule Thesis.Submissions.DownloadToken do
  use Ecto.Schema
  import Ecto.Changeset

  alias Thesis.Submissions.Submission

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "download_tokens" do
    belongs_to(:submission, Submission)

    timestamps()
  end

  @required_fields []

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
  end
end
