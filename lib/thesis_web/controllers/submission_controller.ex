defmodule ThesisWeb.SubmissionController do
  use ThesisWeb, :controller
  import Phoenix.LiveView.Controller, only: [live_render: 3]
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
        case Thesis.Repo.insert(
               Thesis.Submission.changeset(%Thesis.Submission{})
               |> Ecto.Changeset.put_assoc(:author, user)
               |> Ecto.Changeset.put_assoc(:assignment, assignment)
             ) do
          {:ok, submission} ->
            filename = submission.id <> Path.extname(file.filename)
            File.cp(file.path, Path.join("uploads", filename))

            # TODO: Add to job queue

            image = determine_image(filename)
            file_url = "#{Application.get_env(:thesis, :uploads_url)}#{filename}"
            cmd = determine_internal_cmd(file_url)

            case Thesis.Repo.insert(
                   Thesis.Job.changeset(%Thesis.Job{}, %{
                     "image" => image,
                     "cmd" => cmd,
                     "filename" => filename
                   })
                   |> Ecto.Changeset.put_assoc(:submission, submission)
                 ) do
              {:ok, job} ->
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

  defp determine_language(filename) do
    case Path.extname(filename) do
      ".java" -> :java
      ".py" -> :python
      _ -> :unknown
    end
  end

  defp determine_image(filename) do
    case determine_language(filename) do
      :java -> "openjdk:13-alpine"
      :python -> "python:alpine"
      :unknown -> "alpine"
    end
  end

  defp determine_internal_cmd(file_url) do
    filename = Path.basename(file_url)

    cmd =
      case determine_language(file_url) do
        :java -> "java #{filename}"
        :python -> "python #{filename}"
        :unknown -> "file #{filename}"
      end

    """
    echo "Fetching submission file..."
    wget -O #{filename} "#{file_url}"
    echo "Running '#{cmd}'"
    #{cmd}
    """
  end
end
