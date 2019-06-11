defmodule Autocheck.Assignments.Configuration do
  use Ecto.Schema
  import Ecto.Changeset

  alias Autocheck.Assignments.Assignment

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "configurations" do
    belongs_to(:assignment, Assignment)
    field(:code, :string)

    timestamps()
  end

  @doc false
  def changeset(configuration, attrs \\ %{}) do
    configuration
    |> cast(attrs, [:code, :assignment_id])
    |> validate_required([:code, :assignment_id])
  end
end
