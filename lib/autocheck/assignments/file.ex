defmodule Autocheck.Assignments.File do
  use Ecto.Schema
  import Ecto.Changeset

  alias Autocheck.Assignments.Assignment

  @derive {Jason.Encoder, only: [:name, :contents]}

  @primary_key false
  @foreign_key_type :binary_id

  schema "assignment_files" do
    field(:contents, :binary)
    field(:name, :string)
    field(:size, :integer, virtual: true)
    belongs_to(:assignment, Assignment)
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:name, :contents])
    |> validate_required([:name, :contents])
  end
end
