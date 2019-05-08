defmodule ThesisWeb.SubmissionController do
  use ThesisWeb, :controller
  import Ecto.Query, only: [from: 2, preload: 2]
  require Logger

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Thesis.Repo.get!(Thesis.Assignment, assignment_id)

    render(conn, "index.html",
      assignment: assignment,
      role: role
    )
  end

  def previous(%Plug.Conn{assigns: %{role: role, user: user}} = conn, %{
        "assignment_id" => assignment_id
      }) do
    assignment = Thesis.Repo.get!(Thesis.Assignment, assignment_id)
    submissions = Thesis.Submissions.list_submissions(user.id, assignment_id)

    render(conn, "previous.html",
      assignment: assignment,
      role: role,
      submissions: submissions
    )
  end

  defp calculate_diff(nil, new_files) do
    Enum.map(new_files, fn %Thesis.File{name: name, contents: text} ->
      diff =
        case Thesis.Diff.diff_text(nil, text) do
          {:ok, {:diff, diff}} -> diff
          {:ok, :nodiff} -> []
          {:ok, :binary} -> []
        end

      %{type: :added, name: name, diff: diff}
    end)
  end

  defp calculate_diff(old_files, new_files) do
    old_files_map =
      Map.new(old_files, fn %Thesis.File{name: name, contents: text} -> {name, text} end)

    new_files_map =
      Map.new(new_files, fn %Thesis.File{name: name, contents: text} -> {name, text} end)

    old_files_set = MapSet.new(Map.keys(old_files_map))
    new_files_set = MapSet.new(Map.keys(new_files_map))

    added_files_set = MapSet.difference(new_files_set, old_files_set)
    removed_files_set = MapSet.difference(old_files_set, new_files_set)
    same_files_set = MapSet.intersection(old_files_set, new_files_set)

    IO.inspect(added_files_set, label: "Added files")
    IO.inspect(removed_files_set, label: "Removed files")
    IO.inspect(same_files_set, label: "Changed files")

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

  def show(conn, %{"id" => submission_id}) do
    submission =
      Thesis.Repo.get!(Thesis.Submission, submission_id)
      |> Thesis.Repo.preload([:jobs, :assignment])

    # first job
    job = hd(submission.jobs)

    {:ok, events} = EventStore.read_stream_forward(job.id)

    live_render(conn, ThesisWeb.SubmissionLiveView,
      session: %{
        submission: submission,
        assignment: submission.assignment,
        job: job,
        events: events
      }
    )
  end

  def files(conn, %{"id" => submission_id}) do
    file_query = Thesis.Submissions.file_with_contents_query()

    submission =
      Thesis.Repo.get!(Thesis.Submission, submission_id)
      |> Thesis.Repo.preload([[files: file_query], :assignment])

    assignment_id = submission.assignment_id
    inserted_at = submission.inserted_at

    previous_submission =
      Thesis.Repo.one(
        from(s in Thesis.Submission,
          where: s.assignment_id == ^assignment_id and s.inserted_at < ^inserted_at,
          order_by: [desc: s.inserted_at],
          limit: 1,
          preload: [files: ^file_query]
        )
      )

    diff = calculate_diff(previous_submission && previous_submission.files, submission.files)

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
    # TODO: Check if valid file type etc...
    assignment = Thesis.Repo.get!(Thesis.Assignment, assignment_id)

    extracted_files = Thesis.Extractor.extract!(file.path)

    files =
      Enum.map(extracted_files, fn {name, contents} ->
        %{name: name, contents: contents}
      end)

    submission_changeset =
      Thesis.Submission.changeset(
        %Thesis.Submission{
          author: user,
          assignment: assignment
        },
        %{
          jobs: [],
          files: files
        }
      )

    submission = Thesis.Repo.insert!(submission_changeset)

    token_changeset =
      Thesis.DownloadToken.changeset(%Thesis.DownloadToken{submission: submission})

    {:ok, %{job: job, token: _token}} =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:token, token_changeset)
      |> Ecto.Multi.insert(
        :job,
        fn %{token: token} ->
          download_url =
            Application.get_env(:thesis, :submission_download_hostname) <>
              Routes.submission_path(conn, :download, token.id)

          Thesis.Job.changeset(
            %Thesis.Job{submission: submission},
            %{
              image: "python:alpine",
              cmd: "echo '#{download_url}'"
            }
          )
        end
      )
      |> Thesis.Repo.transaction()

    {:ok, coderunner} = Thesis.Coderunner.start_link()
    Thesis.Coderunner.process(coderunner, job)

    redirect(conn, to: Routes.submission_path(conn, :show, submission.id))
  end

  defp get_download_token(token_id), do: Thesis.Repo.get!(Thesis.DownloadToken, token_id)

  # defp remove_download_token(token) do
  #   case Thesis.Repo.delete(token) do
  #     {:ok, _} -> :ok
  #     {:error, error} -> raise error
  #   end
  # end

  defp get_files(submission_id) do
    submission =
      Thesis.Submission
      |> preload(:files)
      |> Thesis.Repo.get!(submission_id)

    submission.files
  end

  defp get_configuration(submission_id) do
    submission =
      Thesis.Submission
      |> preload(:assignment)
      |> Thesis.Repo.get!(submission_id)

    configuration = Thesis.Repo.one(
      from(
        Thesis.Configuration,
        where: [assignment_id: ^submission.assignment.id],
        order_by: [desc: :inserted_at],
        limit: 1
      )
    )

    Thesis.DSL.Parser.parse_dsl(configuration.code)
  end

  def download(conn, %{"token_id" => id}) do
    token = get_download_token(id)
    # TODO: Uncomment to enable download token removal (One-time-use tokens)
    # remove_download_token(token)

    files =
      get_files(token.submission_id)
      |> Enum.map(fn file -> %Thesis.File{file | contents: Base.encode64(file.contents)} end)

    data = 
      get_configuration(token.submission_id)
      |> Map.put(:files, files)
      |> IO.inspect()

    render(conn, "download.json", data: data)
  end
end
