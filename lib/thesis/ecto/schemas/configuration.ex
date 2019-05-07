defmodule Thesis.Configuration do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "configurations" do
    belongs_to(:assignment, Thesis.Assignment)
    has_many(:steps, Thesis.Step)
    field(:environment, :string)
    field(:image, :string)
    field(:required_files, {:array, :string})

    timestamps()
  end

  @doc false
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, [:environment, :image, :required_files])
    |> cast_assoc(:steps)
    |> validate_required([:environment, :image, :required_files])
  end
end
