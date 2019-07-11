defmodule Autocheck.Assignments do
  alias Autocheck.Repo
  alias Autocheck.SharedQuery

  alias Autocheck.Assignments.{
    Assignment,
    Configuration,
    File,
    GradePassback,
    GradePassbackResult
  }

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

    def with_job(queryable) do
      queryable
      |> preload(:job)
    end

    def where_user(queryable, user_id) do
      queryable
      |> where([q], q.user_id == ^user_id)
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
    |> SharedQuery.order_by_insertion_time()
    |> SharedQuery.limit()
    |> Repo.one!()
  end

  def get_default_configuration() do
    %Configuration{
      code: """
      @env "elixir",
        version: "1.7"

      step "Help" do
        help
      end

      step "Hello world" do
        run "echo 'Hello world'"
      end

      step "Will fail" do
        run "exit 1"
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

  def set_grade_passback!(assignment, user, lis_outcome_service_url, lis_result_sourcedid) do
    %GradePassback{}
    |> GradePassback.changeset(%{
      lis_outcome_service_url: lis_outcome_service_url,
      lis_result_sourcedid: lis_result_sourcedid
    })
    |> Ecto.Changeset.put_assoc(:assignment, assignment)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert!(on_conflict: :replace_all, conflict_target: [:assignment_id, :user_id])
  end

  def get_grade_passback!(assignment_id, user_id) do
    GradePassback
    |> Query.where_assignment(assignment_id)
    |> Query.where_user(user_id)
    |> Repo.one!()
  end

  def get_grade_passback_result!(grade_passback_result_id) do
    GradePassbackResult
    |> Query.with_job()
    |> Repo.get!(grade_passback_result_id)
  end

  def queue_result_report!(job) do
    %GradePassbackResult{}
    |> GradePassbackResult.changeset()
    |> Ecto.Changeset.put_assoc(:job, job)
    |> Repo.insert!()
  end
end
