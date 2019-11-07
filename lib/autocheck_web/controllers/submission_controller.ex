defmodule AutocheckWeb.SubmissionController do
  use AutocheckWeb, :controller

  alias Autocheck.Configuration
  alias Autocheck.Assignments
  alias Autocheck.Submissions
  alias Autocheck.Coderunner

  require Logger

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Assignments.get!(assignment_id)
    configuration = Assignments.get_latest_configuration!(assignment.id)

    %AutocheckLanguage.Configuration{
      allowed_file_extensions: allowed_file_extensions,
      required_files: required_files
    } = Configuration.parse_code(configuration.code)

    render(conn, "index.html",
      assignment: assignment,
      allowed_file_extensions: allowed_file_extensions,
      required_files: required_files,
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
      events =
        case EventStore.read_stream_forward(job.id) do
          {:ok, events} -> events
          {:error, _} -> []
        end

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

  @doc """

  Check whether uploaded files have an allowed file extension.

  Returns {:error, invalid_files} or :ok

  ## Examples

    iex> AutocheckWeb.SubmissionController.files_extensions_valid?(
    ...>   [".txt", ".ex"],
    ...>   [%Plug.Upload{filename: "test.txt"}]
    ...> )
    :ok

    iex> AutocheckWeb.SubmissionController.files_extensions_valid?(
    ...>   [".txt", ".ex"],
    ...>   [
    ...>     %Plug.Upload{filename: "test.txt"},
    ...>     %Plug.Upload{filename: "test.png"}
    ...>   ]
    ...> )
    {:error, [%Plug.Upload{filename: "test.png"}]}

    iex> AutocheckWeb.SubmissionController.files_extensions_valid?(
    ...>   [],
    ...>   [
    ...>     %Plug.Upload{filename: "test.txt"},
    ...>     %Plug.Upload{filename: "test.png"}
    ...>   ]
    ...> )
    :ok

  """
  @spec files_extensions_valid?(allowed_exts :: list(String.t()), files :: list(Plug.Upload.t())) ::
          :ok | {:error, list(Plug.Upload.t())}
  def files_extensions_valid?(allowed_exts, files) do
    case not Enum.empty?(allowed_exts) &&
           Enum.filter(files, fn file ->
             !Enum.any?(allowed_exts, fn ext ->
               String.ends_with?(file.filename, ext)
             end)
           end) do
      false -> :ok
      [] -> :ok
      files -> {:error, files}
    end
  end

  @spec validate_file_extensions(allowed_exts :: list(String.t()), files :: list(Plug.Upload.t())) ::
          :ok | {:error, String.t()}
  defp validate_file_extensions(allowed_exts, files) do
    case files_extensions_valid?(allowed_exts, files) do
      :ok ->
        :ok

      {:error, files} ->
        invalid_files_string =
          files
          |> Enum.map(fn %Plug.Upload{filename: filename} -> filename end)
          |> Enum.join(", ")

        allowed_exts_string = Enum.join(allowed_exts, ", ")

        {:error,
         "Invalid file extension for file(s): #{invalid_files_string}, allowed: #{
           allowed_exts_string
         }"}
    end
  end

  @spec extract_possible_archives(files :: list(Plug.Upload.t())) ::
          list(%{name: String.t(), contents: term()})
  defp extract_possible_archives(files) do
    Enum.flat_map(files, fn file ->
      if Enum.any?([".tar", ".tar.gz", ".zip"], &String.ends_with?(file.filename, &1)) do
        extracted_files = Autocheck.Extractor.extract!(file.path)
        for {name, contents} <- extracted_files, do: %{name: name, contents: contents}
      else
        [%{name: file.filename, contents: Elixir.File.read!(file.path)}]
      end
    end)
  end

  @spec validate_required_files(
          required_files :: list(String.t()),
          files :: list(%{name: String.t(), contents: term()})
        ) :: :ok | {:error, String.t()}
  defp validate_required_files(required_files, files) do
    filenames = Enum.map(files, &Map.fetch!(&1, :name))
    missing_files = MapSet.difference(MapSet.new(required_files), MapSet.new(filenames))

    if Enum.empty?(missing_files) do
      :ok
    else
      missing_files_string = Enum.join(missing_files, ", ")
      {:error, "Missing required file(s): #{missing_files_string}"}
    end
  end

  def submit(%Plug.Conn{assigns: %{user: user}} = conn, %{
        "files" => uploaded_files,
        "assignment_id" => assignment_id,
        "comment" => comment
      }) do
    assignment = Assignments.get!(assignment_id)
    configuration = Assignments.get_latest_configuration!(assignment.id)

    %AutocheckLanguage.Configuration{
      allowed_file_extensions: allowed_file_extensions,
      required_files: required_files
    } = Configuration.parse_code(configuration.code)

    with :ok <- validate_file_extensions(allowed_file_extensions, uploaded_files),
         files <- extract_possible_archives(uploaded_files),
         :ok <- validate_required_files(required_files, files) do
      submission =
        Submissions.create!(user, assignment, %{jobs: [], files: files, comment: comment})

      job = Submissions.create_job!(submission)
      Autocheck.Coderunner.start_event_stream(job)

      redirect(conn, to: Routes.submission_path(conn, :show, submission.id))
    else
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: current_path(conn))
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
    assignment = Assignments.get_with_files_with_content!(submission.assignment_id)

    assignment_files =
      for f <- assignment.files, do: %Assignments.File{f | contents: Base.encode64(f.contents)}

    submission_files =
      for f <- submission.files, do: %Submissions.File{f | contents: Base.encode64(f.contents)}

    configuration = Assignments.get_latest_configuration!(submission.assignment_id)

    data =
      Autocheck.Configuration.parse_code(configuration.code)
      |> Map.from_struct()
      |> Map.put(:assignment_files, assignment_files)
      |> Map.put(:submission_files, submission_files)
      |> Map.put(:job_id, job.id)

    render(conn, "download.json", data: data)
  end

  def download_callback(conn, %{"token" => token, "result" => result}) do
    job = Submissions.get_job_by_download_token!(token)

    Coderunner.append_to_stream(job, {:result, result})
    Submissions.finish_job!(job, result)
    Assignments.queue_result_report!(job)

    render(conn, "download_callback.json", job: job)
  end
end
