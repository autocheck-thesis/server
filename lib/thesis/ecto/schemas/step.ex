defmodule Thesis.Step do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "steps" do
    belongs_to(:configuration, Thesis.Configuration)
    field(:commands, {:array, :string})
    field(:name, :string)

    timestamps()
  end

  @doc false
  def changeset(step, attrs) do
    step
    |> cast(attrs, [:name, :commands])
    |> validate_required([:name, :commands])
  end
end
