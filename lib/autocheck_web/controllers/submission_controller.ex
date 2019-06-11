defmodule AutocheckWeb.SubmissionController do
  use AutocheckWeb, :controller

  alias Autocheck.Configuration
  alias Autocheck.Assignments
  alias Autocheck.Submissions
  alias Autocheck.Submissions.File

  require Logger

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Assignments.get!(assignment_id)
    configuration = Assignments.get_latest_configuration!(assignment.id)

    %Configuration{allowed_file_extensions: allowed_file_extensions} =
      Configuration.parse_code(configuration.code)

    render(conn, "index.html",
      assignment: assignment,
      allowed_file_extensions: allowed_file_extensions,
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

  def show(%Plug.Conn{assigns: %{role: role}} = conn, %{"id" => submission_id}) do
    submission = Submissions.get_with_jobs!(submission_id)

    with [job | _jobs] <- submission.jobs do
      {:ok, events} = EventStore.read_stream_forward(job.id)

      live_render(conn, AutocheckWeb.SubmissionLiveView,
        session: %{
          submission: submission,
          job: job,
          events: events,
          role: role
        }
      )
    else
      _ ->
        live_render(conn, AutocheckWeb.SubmissionLiveView,
          session: %{
            submission: submission,
            role: role
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
        "assignment_id" => assignment_id,
        "comment" => comment
      }) do
    assignment = Assignments.get!(assignment_id)
    configuration = Assignments.get_latest_configuration!(assignment.id)

    %Configuration{
      allowed_file_extensions: allowed_file_extensions,
      required_files: required_files
    } = Configuration.parse_code(configuration.code)

    if not Enum.empty?(allowed_file_extensions) and
         not Enum.any?(allowed_file_extensions, &String.ends_with?(file.filename, &1)) do
      allowed_list = Enum.join(allowed_file_extensions, ", ")
      Logger.debug("Invalid file extension for file '#{file.filename}', allowed: #{allowed_list}")

      conn
      |> put_flash(
        :error,
        "Invalid file extension for file '#{file.filename}', allowed: #{allowed_list}"
      )
      |> redirect(to: current_path(conn))
    else
      files =
        if Enum.any?([".tar", ".tar.gz", ".zip"], &String.ends_with?(file.filename, &1)) do
          extracted_files = Autocheck.Extractor.extract!(file.path)
          for {name, contents} <- extracted_files, do: %{name: name, contents: contents}
        else
          [%{name: file.filename, contents: Elixir.File.read!(file.path)}]
        end

      filenames = Enum.map(files, fn %{name: name} -> name end)
      missing_files = MapSet.difference(MapSet.new(required_files), MapSet.new(filenames))

      if not Enum.empty?(missing_files) do
        missing_files_list = Enum.join(missing_files, ", ")
        Logger.debug("Missing required file(s): #{missing_files_list}")

        conn
        |> put_flash(:error, "Missing required file(s): #{missing_files_list}")
        |> redirect(to: current_path(conn))
      end

      submission =
        Submissions.create!(user, assignment, %{jobs: [], files: files, comment: comment})

      job = Submissions.create_job!(submission)
      Autocheck.Coderunner.start_event_stream(job)

      redirect(conn, to: Routes.submission_path(conn, :show, submission.id))
    end
  end

  def submit(conn, %{"assignment_id" => _assignment_id}) do
    conn
    |> put_flash(:error, "No file was specified")
    |> redirect(to: current_path(conn))
  end

  def download(conn, %{"token" => token}) do
    job = Submissions.get_job_by_download_token!(token)
    submission = Submissions.get_with_files_with_content!(job.submission_id)

    files = for f <- submission.files, do: %File{f | contents: Base.encode64(f.contents)}

    configuration = Assignments.get_latest_configuration!(submission.assignment_id)

    data =
      Autocheck.Configuration.parse_code(configuration.code)
      |> Map.from_struct()
      |> Map.put(:files, files)
      |> Map.put(:job_id, job.id)

    render(conn, "download.json", data: data)
  end

  def download_callback(conn, %{"token" => token, "result" => result, "worker_pid" => worker_pid}) do
    job = Submissions.get_job_by_download_token!(token)
    # submission = Submissions.get_with_files_with_content!(job.submission_id)

    # This could be replaced by a registry of running workers
    # Not worse than what honeydew already does
    {:ok, pid_binary} = Base.decode64(worker_pid)
    pid = :erlang.binary_to_term(pid_binary, [:safe])
    send(pid, {:result, result})

    render(conn, "download_callback.json", job: job)
  end
end
