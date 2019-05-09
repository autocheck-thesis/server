defmodule Thesis.Submissions.File do
  use Ecto.Schema
  import Ecto.Changeset

  alias Thesis.Submissions.Submission

  @derive {Jason.Encoder, only: [:name, :contents]}

  @primary_key false
  @foreign_key_type :binary_id

  schema "files" do
    field(:contents, :binary)
    field(:name, :string)
    field(:size, :integer, virtual: true)
    belongs_to(:submission, Submission)
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:name, :contents])
    |> validate_required([:name, :contents])
  end
end
