defmodule ThesisWeb.SubmissionController do
  use ThesisWeb, :controller
  import Ecto.Query, only: [from: 2, preload: 2]
  require Logger

  alias Thesis.Assignments
  alias Thesis.Submissions
  alias Thesis.Submissions.File

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Assignments.get!(assignment_id)

    render(conn, "index.html",
      assignment: assignment,
      role: role
    )
  end

  def previous(%Plug.Conn{assigns: %{role: role, user: user}} = conn, %{
        "assignment_id" => assignment_id
      }) do
    assignment = Assignments.get!(assignment_id)
    submissions = Submissions.list_by_author_and_assignment(user.id, assignment_id)

    render(conn, "previous.html",
      assignment: assignment,
      role: role,
      submissions: submissions
    )
  end

  def show(conn, %{"id" => submission_id}) do
    submission = Submissions.get_with_jobs!(submission_id)

    with [job] <- submission.jobs do
      {:ok, events} = EventStore.read_stream_forward(job.id)

      live_render(conn, ThesisWeb.SubmissionLiveView,
        session: %{
          submission: submission,
          job: job,
          events: events
        }
      )
    else
      _ ->
        live_render(conn, ThesisWeb.SubmissionLiveView,
          session: %{
            submission: submission
          }
        )
    end
  end

  def files(conn, %{"id" => submission_id}) do
    submission = Submissions.get_with_files_with_content!(submission_id)
    previous_submission = Submissions.get_previous_submission(submission)

    diff =
      if previous_submission do
        Submissions.calculate_diff(previous_submission.files, submission.files)
      else
        Submissions.calculate_diff(nil, submission.files)
      end

    render(conn, "files.html",
      submission: submission,
      assignment: submission.assignment,
      diff: diff
    )
  end

  def submit(%Plug.Conn{assigns: %{user: user}} = conn, %{
        "file" => file,
        "assignment_id" => assignment_id
      }) do
    assignment = Assignments.get!(assignment_id)
    _configuration = Assignments.get_latest_configuration!(assignment.id)

    # TODO: Check if valid file type etc...

    extracted_files = Thesis.Extractor.extract!(file.path)

    files = for {name, contents} <- extracted_files, do: %{name: name, contents: contents}

    submission = Submissions.create!(user, assignment, %{jobs: [], files: files})

    token = Submissions.create_download_token!(submission)

    download_url =
      Application.get_env(:thesis, :submission_download_hostname) <>
        Routes.submission_path(conn, :download, token.id)

    job =
      Submissions.create_job!(submission, %{image: "python:alpine", cmd: "echo '#{download_url}'"})

    {:ok, coderunner} = Thesis.Coderunner.start_link()
    Thesis.Coderunner.process(coderunner, job)

    redirect(conn, to: Routes.submission_path(conn, :show, submission.id))
  end

  def download(conn, %{"token_id" => token_id}) do
    submission = Submissions.get_by_token!(token_id)

    files = for f <- submission.files, do: %File{f | contents: Base.encode64(f.contents)}

    configuration = Assignments.get_latest_configuration!(submission.assignment_id)

    data =
      Thesis.DSL.Parser.parse_dsl(configuration.code)
      |> Map.put(:files, files)
      |> IO.inspect()

    # TODO: Uncomment to enable download token removal (One-time-use tokens)
    # Submissions.remove_token!(token)

    render(conn, "download.json", data: data)
  end
end
