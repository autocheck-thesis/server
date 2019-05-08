defmodule Thesis.File do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  @derive {Jason.Encoder, only: [:name, :contents]}

  @primary_key false
  @foreign_key_type :binary_id

  schema "files" do
    field(:contents, :binary)
    field(:name, :string)
    field(:size, :integer, virtual: true)
    belongs_to(:submission, Thesis.Submission)
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:name, :contents])
    |> validate_required([:name, :contents])
  end

  def get_without_contents(name) do
    from(f in __MODULE__, select: [:name])
  end
end
