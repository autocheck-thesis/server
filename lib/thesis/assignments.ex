defmodule Thesis.Assignments do
  alias Thesis.Repo
  alias Thesis.SharedQuery
  alias Thesis.Assignments.{Assignment, Configuration}

  defmodule Query do
    import Ecto.Query

    def with_configurations(queryable) do
      queryable
      |> preload(:configurations)
      |> SharedQuery.order_by_insertion_time()
    end

    def where_assignment(queryable, assignment_id) do
      queryable
      |> where([q], q.assignment_id == ^assignment_id)
      |> SharedQuery.order_by_insertion_time()
    end
  end

  def get!(id) do
    Assignment
    |> Repo.get!(id)
  end

  def get_latest_configuration!(assignment_id) do
    Configuration
    |> Query.where_assignment(assignment_id)
    |> SharedQuery.limit()
    |> Repo.one!()
  end

  def get_default_configuration() do
    %Configuration{
      code: """
      @env "elixir",
        version: "1.7"

      @required_files "test.ex"

      step "Basic test" do
        format "/tmp/files/test.ex"
        help
      end

      step "Hello world" do
        run "echo 'Hello world'"
      end
      """
    }
  end

  def get_or_insert!(attrs \\ %{}) do
    Repo.get_or_insert!(Assignment, attrs)
  end

  def create_configuration!(attrs \\ %{}) do
    %Configuration{}
    |> Configuration.changeset(attrs)
    |> Repo.insert!()
  end
end
