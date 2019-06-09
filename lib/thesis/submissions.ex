defmodule Thesis.Submissions do
  alias Thesis.Repo
  alias Thesis.SharedQuery
  alias Thesis.Submissions.{Submission, File, Job}

  defmodule Query do
    import Ecto.Query

    def where_author(queryable, author_id) do
      queryable
      |> where([q], q.author_id == ^author_id)
      |> SharedQuery.order_by_insertion_time()
    end

    def where_assignment(queryable, assignment_id) do
      queryable
      |> where([q], q.assignment_id == ^assignment_id)
      |> SharedQuery.order_by_insertion_time()
    end

    def where_submission(queryable, submission_id) do
      queryable
      |> where([q], q.submission_id == ^submission_id)
      |> SharedQuery.order_by_insertion_time()
    end

    def with_assignment(queryable) do
      queryable
      |> preload(:assignment)
    end

    def with_jobs(queryable) do
      queryable
      |> preload(jobs: ^from(j in Job, order_by: [desc: j.inserted_at]))
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

    def where_older_than(queryable, time) do
      queryable
      |> where([q], q.inserted_at < ^time)
    end

    def limit(queryable, limit \\ 1) do
      queryable
      |> Ecto.Query.limit(^limit)
    end
  end

  def list(queryable \\ Submission) do
    queryable
    |> Query.with_files()
    |> Repo.all()
  end

  def list_by_author(queryable \\ Submission, author_id) do
    queryable
    |> Query.where_author(author_id)
    |> Query.with_assignment()
    |> Query.with_files()
    |> Repo.all()
  end

  def list_by_author_and_assignment(queryable \\ Submission, author_id, assignment_id) do
    queryable
    |> Query.where_author(author_id)
    |> Query.where_assignment(assignment_id)
    |> Query.with_files()
    |> Repo.all()
  end

  def get!(id) do
    Submission
    |> Query.with_assignment()
    |> Repo.get!(id)
  end

  def get_with_jobs!(id) do
    Submission
    |> Query.with_assignment()
    |> Query.with_files()
    |> Query.with_jobs()
    |> Repo.get!(id)
  end

  def get_with_files!(id) do
    Submission
    |> Query.with_files()
    |> Repo.get!(id)
  end

  def get_with_files_with_content!(id) do
    Submission
    |> Query.with_files_with_content()
    |> Repo.get!(id)
  end

  def get_previous_submission(submission) do
    Submission
    |> Query.where_assignment(submission.assignment_id)
    |> Query.where_older_than(submission.inserted_at)
    |> Query.with_files_with_content()
    |> Query.limit()
    |> Repo.one()
  end

  def get_job_by_download_token!(token) do
    Job
    |> Repo.get_by!(download_token: token)
  end

  def create!(author, assignment, attrs \\ %{}) do
    %Submission{}
    |> Submission.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:author, author)
    |> Ecto.Changeset.put_assoc(:assignment, assignment)
    |> Repo.insert!()
  end

  def get_job!(job_id) do
    Repo.get!(Job, job_id)
  end

  def create_job!(submission, attrs \\ %{}) do
    %Job{}
    |> Job.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:submission, submission)
    |> Repo.insert!()
  end

  def remove_job_download_token!(job) do
    job
    |> Ecto.Changeset.change(download_token: nil)
    |> Repo.update!()
  end

  def finish_job!(job, result) do
    job
    |> Ecto.Changeset.change(finished: true)
    |> Ecto.Changeset.change(result: result)
    |> Repo.update!()
  end

  def remove_token!(token) do
    Repo.delete!(token)
  end

  def calculate_diff(nil, new_files) do
    Enum.map(new_files, fn %File{name: name, contents: text} ->
      diff =
        case Thesis.Diff.diff_text(nil, text) do
          {:ok, {:diff, diff}} -> diff
          {:ok, :nodiff} -> []
          {:ok, :binary} -> []
        end

      %{type: :added, name: name, diff: diff}
    end)
  end

  def calculate_diff(old_files, new_files) do
    old_files_map = Map.new(old_files, fn %File{name: name, contents: text} -> {name, text} end)

    new_files_map = Map.new(new_files, fn %File{name: name, contents: text} -> {name, text} end)

    old_files_set = MapSet.new(Map.keys(old_files_map))
    new_files_set = MapSet.new(Map.keys(new_files_map))

    added_files_set = MapSet.difference(new_files_set, old_files_set)
    removed_files_set = MapSet.difference(old_files_set, new_files_set)
    same_files_set = MapSet.intersection(old_files_set, new_files_set)

    # IO.inspect(added_files_set, label: "Added files")
    # IO.inspect(removed_files_set, label: "Removed files")
    # IO.inspect(same_files_set, label: "Changed files")

    Enum.map(added_files_set, fn name ->
      text = Map.get(new_files_map, name)

      diff =
        case Thesis.Diff.diff_text(nil, text) do
          {:ok, {:diff, diff}} -> diff
          {:ok, :nodiff} -> []
          {:ok, :binary} -> []
        end

      %{type: :added, name: name, diff: diff}
    end) ++
      Enum.map(same_files_set, fn name ->
        old_text = Map.get(old_files_map, name)
        new_text = Map.get(new_files_map, name)

        {type, diff} =
          case Thesis.Diff.diff_text(old_text, new_text) do
            {:ok, {:diff, diff}} ->
              {:changed, diff}

            {:ok, :nodiff} ->
              diff = new_text |> String.split("\n") |> Enum.map(fn line -> {:eq, line} end)
              {:unchanged, diff}

            {:ok, :binary} ->
              {:unchanged, []}
          end

        %{type: type, name: name, diff: diff}
      end) ++
      Enum.map(removed_files_set, fn name ->
        text = Map.get(old_files_map, name)

        diff =
          case Thesis.Diff.diff_text(text, nil) do
            {:ok, {:diff, diff}} -> diff
            {:ok, :nodiff} -> []
            {:ok, :binary} -> []
          end

        %{type: :removed, name: name, diff: diff}
      end)
  end
end
