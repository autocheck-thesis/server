defmodule ThesisWeb.JobController do
  use ThesisWeb, :controller
  import Phoenix.LiveView.Controller, only: [live_render: 3]
  require Logger

  def index(conn, _params) do
    render(conn, "index.html", [
      assignment_id: get_session(conn, :assignment_id),
      role: get_session(conn, :role)
    ])
  end

  def show(conn, %{"id" => job_id} = _params) do
    {:ok, events} = EventStore.read_stream_forward(job_id)

    live_render(conn, ThesisWeb.JobLiveView,
      session: %{user_id: 0, job_id: job_id, events: events}
    )
  end

  def show(conn, _params) do
    redirect(conn, to: ThesisWeb.Router.Helpers.job_path(conn, :index))
  end

  def submit_student(conn, %{"file" => file} = _params) do
    assignment_id = get_session(conn, "assignment_id")

    case :ets.lookup(:assignment_tests, assignment_id) do
      [] ->
        redirect(conn, to: Routes.job_path(conn, :index))
      [{_, test_file_path}] ->
        File.cp(file.path, "D:/tmp/submission/#{file.filename}")

        language = determine_language(test_file_path)
        image = determine_image(language)
        internal_cmd = determine_internal_cmd(language, test_file_path)
        job_id = :crypto.strong_rand_bytes(10) |> Base.encode16()

        job = %Thesis.JobWorker.Job{
          id: job_id,
          image: image,
          cmd: [
            "sh",
            "-c",
            """
            cd /tmp/submission
            #{internal_cmd}
            """
          ],
          filename: test_file_path,
          filepath: "D:/tmp/submission/",
          stream_id: job_id
        }

        {:ok, docker_conn} = Thesis.JobWorker.start_link()
        Thesis.JobWorker.process(docker_conn, job)

        redirect(conn, to: ThesisWeb.Router.Helpers.job_path(conn, :show, job.id))
    end
  end

  def submit_teacher(conn, %{"file" => file} = _params) do
    assignment_id = get_session(conn, "assignment_id")
    File.cp(file.path, "D:/tmp/submission/#{file.filename}")
    :ets.insert(:assignment_tests, {assignment_id, file.filename})

    conn
    |> put_flash(:info, "Success")
    |> redirect(to: Routes.job_path(conn, :index))
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
    case language do
      :java -> "java #{filename}"
      :python -> "python #{filename}"
      :unknown -> "file #{filename}"
    end
  end
end
