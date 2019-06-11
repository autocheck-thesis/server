defmodule Autocheck.Accounts do
  alias Autocheck.Repo
  alias Autocheck.Accounts.{User}

  # defmodule Query do
  #   import Ecto.Query
  # end

  def get_or_insert!(attrs \\ %{}) do
    Repo.get_or_insert!(User, attrs)
  end

  def get!(queryable \\ User, id) do
    queryable
    |> Repo.get!(id)
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
