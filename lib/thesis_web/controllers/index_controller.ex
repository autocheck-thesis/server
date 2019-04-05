defmodule ThesisWeb.IndexController do
  use ThesisWeb, :controller

  require Logger

  plug PlugLti when action in [:launch]
  plug :fetch_session

  def launch(conn, params) do
    user_id = params["user_id"]
    user = Thesis.User.find_or_create(user_id)
    conn = put_session(conn, :user, user)

    if params["ext_lti_assignment_id"] && params["custom_canvas_assignment_title"] do
      assignment_id = params["ext_lti_assignment_id"]
      assignment_name = params["custom_canvas_assignment_title"]

      redirect(conn, to: Routes.submission_path(conn, :index, assignment_id, assignment_name))
    else
      text(conn, "No assignment specified.")
    end
  end

  def index(conn, _params) do
    user = get_session(conn, :user)

    conn |> text("Welcome back user #{user.id} with lti_user_id #{user.lti_user_id}.")

    # Phoenix.LiveView.Controller.live_render(conn, ThesisWeb.TestLiveView, session: %{})
  end
end
