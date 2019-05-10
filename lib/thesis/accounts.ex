defmodule Thesis.Accounts do
  alias Thesis.Repo
  alias Thesis.Accounts.{User}

  # defmodule Query do
  #   import Ecto.Query
  # end

  def get_or_insert!(attrs \\ %{}) do
    Repo.get_or_insert!(User, attrs)
  end

  def determine_role(roles) do
    cond do
      roles =~ "Learner" ->
        :student

      roles =~ "Instructor" ->
        :teacher

      true ->
        :unknown
    end
  end
end
