defmodule ThesisWeb.SubmissionController do
  use ThesisWeb, :controller
  import Ecto.Query, only: [from: 2, preload: 2]
  require Logger

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Thesis.Repo.get!(Thesis.Assignment, assignment_id)

    submissions =
      Thesis.Repo.all(
        from(Thesis.Submission,
          where: [assignment_id: ^assignment_id],
          order_by: [desc: :inserted_at]
        )
      )

    render(conn, "index.html",
      assignment: assignment,
      role: role,
      submissions: submissions
    )
  end

  def show(conn, %{"id" => submission_id}) do
    submission =
      Thesis.Repo.get!(Thesis.Submission, submission_id)
      |> Thesis.Repo.preload(:jobs)

    # first job
    job = hd(submission.jobs)

    {:ok, events} = EventStore.read_stream_forward(job.id)

    live_render(conn, ThesisWeb.SubmissionLiveView,
      session: %{submission: submission, job: job, events: events}
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

  def download(conn, %{"token_id" => id}) do
    token = get_download_token(id)
    # TODO: Uncomment to enable download token removal (One-time-use tokens)
    # remove_download_token(token)
    data =
      get_files(token.submission_id)
      |> Enum.map(fn file -> %Thesis.File{file | contents: Base.encode64(file.contents)} end)

    render(conn, "download.json", data: data)
  end
end
