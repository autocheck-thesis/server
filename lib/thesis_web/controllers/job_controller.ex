defmodule ThesisWeb.JobController do
  use ThesisWeb, :controller
  import Phoenix.LiveView.Controller, only: [live_render: 3]
  require Logger

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => job_id} = _params) do
    live_render(conn, ThesisWeb.JobLiveView, session: %{user_id: 0, job_id: job_id})
  end

  def show(conn, _params) do
    redirect(conn, to: ThesisWeb.Router.Helpers.job_path(conn, :submit))
  end

  def submit(conn, %{"file" => file} = _params) do
    File.cp(file.path, "/Users/nikteg/tmp/submission/#{file.filename}")

    language = determine_language(file.filename)
    image = determine_image(language)
    internal_cmd = determine_internal_cmd(language, file.filename)

    job = %Thesis.Job{
      id: :crypto.strong_rand_bytes(10) |> Base.encode16(),
      image: image,
      cmd: [
        "sh",
        "-c",
        """
        cd /tmp/submission
        #{internal_cmd}
        """
      ],
      filename: file.filename,
      filepath: "/Users/nikteg/tmp/submission/"
    }

    {:ok, docker_conn} = Thesis.JobWorker.start_link()
    Thesis.JobWorker.process(docker_conn, job)

    redirect(conn, to: ThesisWeb.Router.Helpers.job_path(conn, :show, job.id))
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
