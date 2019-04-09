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

    File.cp(file.path, Path.join("uploads", submission.id <> Path.extname(file.filename)))

    # TODO: Add to job queue

    language = determine_language(file.filename)
    image = determine_image(language)
    cmd = Thesis.Repo.get_by!(Thesis.Assignment, [assignment_id: assignment_id, name: assignment_name]).cmd

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

  defp determine_image(language) do
    case language do
      :java -> "openjdk:13-alpine"
      :python -> "python:alpine"
      :unknown -> "alpine"
    end
  end

  defp determine_internal_cmd(language, filename) do
    # case language do
    #   :java -> "java #{filename}"
    #   :python -> "python #{filename}"
    #   :unknown -> "file #{filename}"
    # end
    """
    for i in $(seq 1 10)
    do
      echo $i
      sleep 0.1
    done
    """
  end
end
