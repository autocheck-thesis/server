defmodule ThesisWeb.SubmissionController do
  use ThesisWeb, :controller
  import Ecto.Query, only: [from: 2]
  require Logger

  def index(conn, %{"assignment_id" => assignment_id}) do
    case Thesis.Repo.get(Thesis.Assignment, assignment_id) do
      nil ->
        raise "Assignment not found"

      assignment ->
        submissions =
          Thesis.Repo.all(
            from(Thesis.Submission,
              where: [assignment_id: ^assignment_id],
              order_by: [desc: :inserted_at]
            )
          )

        render(conn, "index.html",
          assignment: assignment,
          role: get_session(conn, :role),
          submissions: submissions
        )
    end
  end

  def index(conn, _params) do
    conn |> send_resp(400, "Assignment id and name must be specified.") |> halt()
  end

  def show(conn, %{"id" => submission_id}) do
    submission = Thesis.Repo.get!(Thesis.Submission, submission_id) |> Thesis.Repo.preload(:jobs)

    # first job
    job = hd(submission.jobs)

    {:ok, events} = EventStore.read_stream_forward(job.id)

    live_render(conn, ThesisWeb.SubmissionLiveView,
      session: %{user_id: 0, submission: submission, job: job, events: events}
    )
  end

  def show(conn, _params) do
    conn |> send_resp(400, "Submission id and name must be specified.") |> halt()
  end

  def submit(conn, %{
        "file" => file,
        "assignment_id" => assignment_id
      }) do
    user = get_session(conn, :user)

    case Thesis.Repo.get(Thesis.Assignment, assignment_id) do
      nil ->
        raise "Assignment not found"

      assignment ->
        # TODO: Check if valid file type etc...
        case Thesis.Repo.insert(
               Thesis.Submission.changeset(%Thesis.Submission{})
               |> Ecto.Changeset.put_assoc(:author, user)
               |> Ecto.Changeset.put_assoc(:assignment, assignment)
             ) do
          {:ok, submission} ->
            File.cp(file.path, Path.join("uploads", submission.id))

            # TODO: Add to job queue

            case Ecto.Multi.new()
                 |> Ecto.Multi.insert(
                   :token,
                   Thesis.DownloadToken.changeset(%Thesis.DownloadToken{})
                   |> Ecto.Changeset.put_assoc(:submission, submission)
                 )
                 |> Ecto.Multi.insert(
                   :job,
                   fn %{token: token} ->
                     download_url =
                       Application.get_env(:thesis, :submission_download_hostname) <>
                         Routes.submission_path(conn, :download, token.id)

                     {image, cmd} = determine_image_and_cmd(file.filename)

                     full_cmd = Thesis.DSL.parse_dsl(assignment.dsl)
                      #  determine_internal_cmd(
                      #    download_url,
                      #    file.filename,
                      #    cmd
                      #  )

                     Thesis.Job.changeset(%Thesis.Job{}, %{
                       "image" => image,
                       "cmd" => full_cmd
                     })
                     |> Ecto.Changeset.put_assoc(:submission, submission)
                   end
                 )
                 |> Thesis.Repo.transaction() do
              {:ok, %{job: job, token: _token}} ->
                {:ok, coderunner} = Thesis.Coderunner.start_link()
                Thesis.Coderunner.process(coderunner, job)

                redirect(conn, to: Routes.submission_path(conn, :show, submission.id))

              {:error, error} ->
                raise error
            end

          {:error, error} ->
            raise error
        end
    end
  end

  def download(conn, %{"token_id" => id}) do
    case Thesis.Repo.get(Thesis.DownloadToken, id) do
      nil ->
        raise "Could not find download token"

      token ->
        # TODO: Uncomment to enable download token removal (One-time-use tokens)
        # case Thesis.Repo.delete(token) do
        #   {:ok, _} -> send_file(conn, 200, Path.join("uploads", token.submission_id))
        #   {:error, error} -> raise error
        # end
        send_file(conn, 200, Path.join("uploads", token.submission_id))
    end
  end

  defp determine_language(filename) do
    case Path.extname(filename) do
      ".java" -> :java
      ".py" -> :python
      _ -> :unknown
    end
  end

  defp determine_image_and_cmd(filename) do
    case determine_language(filename) do
      :java ->
        {"openjdk:13-alpine", "java \"#{filename}\""}

      :python ->
        {"python:alpine", "python \"#{filename}\""}

      :unknown ->
        {"alpine", "cat \"#{filename}\""}
    end
  end

  defp determine_internal_cmd(download_url, filename, cmd) do
    """
    echo "wget -O "#{filename}" "#{download_url}""
    wget -O "#{filename}" "#{download_url}"
    cat "#{filename}"
    echo "Running '#{cmd}'"
    #{cmd}
    """
  end
end
