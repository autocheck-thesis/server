defmodule Thesis.Job do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "job" do
    field(:image, :string)
    field(:cmd, :string)
  end
end
