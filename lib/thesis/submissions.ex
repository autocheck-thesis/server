defmodule Thesis.Submissions do
  alias Thesis.Repo
  import Ecto.Query, only: [from: 2]

  alias Thesis.Submission
  alias Thesis.File

  def file_query() do
    from(f in File,
      select: %File{name: f.name, size: fragment("octet_length(contents)")}
    )
  end

  def file_with_contents_query() do
    from(f in File,
      select: %File{
        name: f.name,
        contents: f.contents,
        size: fragment("octet_length(contents)")
      }
    )
  end

  def list_submissions(user_id, assignment_id) do
    query =
      from(s in Submission,
        where: s.author_id == ^user_id and s.assignment_id == ^assignment_id,
        order_by: [desc: s.inserted_at]
      )

    Repo.all(query)
    |> Repo.preload(files: file_query())
  end

  def list_submissions(user_id) do
    query =
      from(s in Submission,
        where: s.author_id == ^user_id
      )

    Repo.all(query)
    |> Repo.preload(files: file_query())
  end

  def get_submission(id) do
    Repo.get(Submission, id)
    |> Repo.preload(files: file_with_contents_query())
  end

  def get_submission!(id) do
    Repo.get!(Submission, id)
    |> Repo.preload(files: file_with_contents_query())
  end
end
