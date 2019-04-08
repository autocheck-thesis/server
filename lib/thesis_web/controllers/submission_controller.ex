defmodule ThesisWeb.SubmissionController do
  use ThesisWeb, :controller
  import Phoenix.LiveView.Controller, only: [live_render: 3]
  require Logger

  def index(conn, %{"assignment_id" => assignment_id, "assignment_name" => assignment_name}) do
    render(conn, "index.html",
      assignment_id: assignment_id,
      assignment_name: assignment_name,
      role: get_session(conn, :role)
    )
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
        "assignment_id" => assignment_id,
        "assignment_name" => assignment_name
      }) do
    user = get_session(conn, :user)

    submission =
      Thesis.Submission.create(assignment_id, assignment_name, user) |> Thesis.Repo.insert!()

    filename = submission.id <> Path.extname(file.filename)
    File.cp(file.path, Path.join("uploads", filename))

    # TODO: Add to job queue

    IO.inspect(Application.get_env(:thesis, :uploads_url))

    image = determine_image(filename)
    file_url = "#{Application.get_env(:thesis, :uploads_url)}#{filename}"
    cmd = determine_internal_cmd(file_url)

    job = Thesis.Job.create(image, cmd, submission.id, submission) |> Thesis.Repo.insert!()

    {:ok, coderunner} = Thesis.Coderunner.start_link()
    Thesis.Coderunner.process(coderunner, job)

    redirect(conn, to: Routes.submission_path(conn, :show, submission.id))
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
