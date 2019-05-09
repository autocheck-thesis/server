defmodule Thesis.Repo do
  use Ecto.Repo,
    otp_app: :thesis,
    adapter: Ecto.Adapters.Postgres

  def get_or_insert(schema, params) do
    case get_by(schema, params) do
      nil ->
        insert(schema.changeset(schema.__struct__, params))

      struct ->
        {:ok, struct}
    end
  end

  def get_or_insert!(schema, params) do
    case get_by(schema, params) do
      nil ->
        insert!(schema.changeset(schema.__struct__, params))

      struct ->
        struct
    end
  end
end
