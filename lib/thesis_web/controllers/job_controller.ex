defmodule ThesisWeb.JobController do
  use ThesisWeb, :controller
  import Phoenix.LiveView.Controller, only: [live_render: 3]
  require Logger

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => job_id} = _params) do
    live_render(conn, ThesisWeb.JobLiveView, session: %{user_id: 0, job_id: String.to_integer(job_id)})
  end

  def show(conn, _params) do
    redirect(conn, to: ThesisWeb.Router.Helpers.job_path(conn, :submit))
  end

  def submit(conn, %{"file" => file} = _params) do
    File.cp(file.path, "/Users/nikteg/tmp/submission/#{file.filename}")

    job = %Thesis.Job{
      id: 1,
      image: "openjdk:13-alpine",
      cmd: [
        "sh",
        "-c",
        """
        cd /tmp/submission
        java "#{file.filename}"
        """
      ],
      filename: file.filename,
      filepath: "/Users/nikteg/tmp/submission/"
    }

    {:ok, docker_conn} = Thesis.JobWorker.start_link()
    Thesis.JobWorker.process(docker_conn, job)

    redirect(conn, to: ThesisWeb.Router.Helpers.job_path(conn, :show, job.id))
  end
end
