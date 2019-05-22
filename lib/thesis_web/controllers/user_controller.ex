defmodule ThesisWeb.UserController do
  use ThesisWeb, :controller
  require Logger

  alias Thesis.Submissions
  alias Thesis.Accounts

  def show(%Plug.Conn{assigns: %{role: :teacher}} = conn, %{"id" => id}) do
    user = Accounts.get!(id)

    render(conn, "show.html", user: user)
  end

  def submissions(%Plug.Conn{assigns: %{role: :teacher}} = conn, %{"id" => id}) do
    user = Accounts.get!(id)
    submissions = Submissions.list_by_author(user.id)

    render(conn, "submissions.html", user: user, submissions: submissions)
  end
end
