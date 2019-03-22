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
    |> redirect(to: "/")
  end

  def index(conn, _params) do
    # user_id = get_session(conn, :user_id)

    # if user_id do
    #   conn
    #   |> render("index.html", user: user_id)
    # else
    #   conn
    #   |> put_status(403)
    #   |> put_view(ThesisWeb.ErrorView)
    #   |> render(:"403")
    # end

    Phoenix.LiveView.Controller.live_render(conn, ThesisWeb.TestLiveView, session: %{})
  end

  def work(conn, _params) do
    user_id = get_session(conn, :user_id)

    Phoenix.LiveView.Controller.live_render(conn, ThesisWeb.LogLiveView,
      session: %{user_id: user_id, images: ["ubuntu", "alpine"]}
    )
  end
end
