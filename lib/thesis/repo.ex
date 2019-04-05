defmodule Thesis.Repo do
  use Ecto.Repo,
    otp_app: :thesis,
    adapter: Ecto.Adapters.Postgres
end
