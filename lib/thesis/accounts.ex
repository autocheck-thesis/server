defmodule Thesis.Accounts do
  alias Thesis.Repo
  alias Thesis.Accounts.{User}

  # defmodule Query do
  #   import Ecto.Query
  # end

  def get_or_insert!(attrs \\ %{}) do
    Repo.get_or_insert!(User, attrs)
  end
end
