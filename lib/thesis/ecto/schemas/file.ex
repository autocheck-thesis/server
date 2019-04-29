defmodule Thesis.File do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:name, :contents]}

  @primary_key false
  @foreign_key_type :binary_id

  schema "files" do
    field(:contents, :binary)
    field(:name, :string)
    belongs_to(:submission, Thesis.Submission)
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:name, :contents])
    |> validate_required([:name, :contents])
  end
end
