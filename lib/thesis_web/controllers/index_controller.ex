defmodule ThesisWeb.IndexController do
  use ThesisWeb, :controller

  require Logger

  plug PlugLti when action in [:launch]
  plug :fetch_session

  def launch(conn, params) do
    conn
    |> put_session(:user_id, params["user_id"])
    |> put_session(:oauth_consumer_key, params["oauth_consumer_key"])
    |> put_session(:lis_result_sourcedid, params["lis_result_sourcedid"])
    |> put_session(:lis_outcome_service_url, params["lis_outcome_service_url"])
    |> put_session(:roles, params["roles"])
    |> redirect(to: "/")
  end

  def index(conn, _params) do
    user_id = get_session(conn, :user_id)
    user_roles = get_session(conn, :roles)

    if user_id && user_roles do
      cond do
        user_roles =~ "Student" ->
          conn |> text("You are a student, #{user_id}.")

        user_roles =~ "Instructor" ->
          conn |> text("You are a teacher, #{user_id}.")

        true ->
          conn |> text("You dont match any role.")
      end
    else
      conn
      |> put_status(403)
      |> put_view(ThesisWeb.ErrorView)
      |> render(:"403")
    end

    # Phoenix.LiveView.Controller.live_render(conn, ThesisWeb.TestLiveView, session: %{})
  end

  def work(conn, _params) do
    user_id = get_session(conn, :user_id)

    # Phoenix.LiveView.Controller.live_render(conn, ThesisWeb.LogLiveView,
    #   session: %{user_id: user_id, images: ["ubuntu", "alpine"]}
    # )
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

    Phoenix.LiveView.Controller.live_render(conn, ThesisWeb.LogLiveView,
      session: %{user_id: 0, job: job}
    )
  end

  def submit(conn, _params) do
    conn |> render("submit.html")
  end
end
