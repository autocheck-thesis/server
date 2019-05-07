defmodule Thesis.Configuration do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "configurations" do
    belongs_to(:assignment, Thesis.Assignment)
    field(:code, :string)

    timestamps()
  end

  @doc false
  def changeset(configuration, attrs \\ %{}) do
    configuration
    |> cast(attrs, [:code])
    |> validate_required([:code])
  end
end
