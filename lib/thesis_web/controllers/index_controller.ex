defmodule ThesisWeb.IndexController do
  use ThesisWeb, :controller

  plug PlugLti when action in [:launch]
  plug :fetch_session

  def launch(conn, params) do
    conn
    |> put_session(:user_id, params["user_id"])
    |> put_session(:oauth_consumer_key, params["oauth_consumer_key"])
    |> redirect(to: "/")
  end

  def index(conn, _params) do
    user_id = get_session(conn, :user_id)

    if user_id do
      conn
      |> text("Welcome back, " <> user_id)
    else
      conn
      |> text("You have no session")
    end
  end
end
