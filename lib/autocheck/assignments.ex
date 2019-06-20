defmodule Autocheck.Assignments do
  alias Autocheck.Repo
  alias Autocheck.SharedQuery
  alias Autocheck.Assignments.{Assignment, Configuration, File}

  defmodule Query do
    import Ecto.Query

    def with_configurations(queryable) do
      queryable
      |> preload(:configurations)
      |> SharedQuery.order_by_insertion_time()
    end

    def with_files(queryable) do
      file_query =
        from(f in File,
          select: %File{name: f.name, size: fragment("octet_length(contents)")},
          order_by: [asc: f.name]
        )

      queryable
      |> preload(files: ^file_query)
    end

    def with_files_with_content(queryable) do
      file_query =
        from(f in File,
          select: %File{
            name: f.name,
            contents: f.contents,
            size: fragment("octet_length(contents)")
          },
          order_by: [asc: f.name]
        )

      queryable
      |> preload(files: ^file_query)
    end

    def where_assignment(queryable, assignment_id) do
      queryable
      |> where([q], q.assignment_id == ^assignment_id)
      |> SharedQuery.order_by_insertion_time()
    end

    def files_with_assignment_id(assignment_id) do
      from(f in File,
        where: f.assignment_id == ^assignment_id
      )
    end

    def where_filename(queryable, filename) do
      queryable
      |> where([f], f.name == ^filename)
    end
  end

  def get!(id) do
    Assignment
    |> Repo.get!(id)
  end

  def get_with_files!(id) do
    Assignment
    |> Query.with_files()
    |> Repo.get!(id)
  end

  def get_with_files_with_content!(id) do
    Assignment
    |> Query.with_files_with_content()
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

  def add_files(assignment_id, files) do
    File
    |> Repo.insert_all(
      Enum.map(files, fn file -> Map.put(file, :assignment_id, assignment_id) end)
    )
  end

  def remove_file(assignment_id, filename) do
    Query.files_with_assignment_id(assignment_id)
    |> Query.where_filename(filename)
    |> Repo.delete_all()
  end

  def remove_all_files(assignment_id) do
    Query.files_with_assignment_id(assignment_id)
    |> Repo.delete_all()
  end
end
