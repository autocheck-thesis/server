defmodule ThesisWeb.UserView do
  use ThesisWeb, :view

  alias Thesis.Accounts.User

  def user_sidebar_items(%Plug.Conn{} = conn, %User{} = user) do
    [
      menu_link(
        "Details",
        Routes.user_path(conn, :show, user.id),
        :user
      ),
      menu_link(
        "Submissions",
        Routes.user_path(conn, :submissions, user.id),
        :submissions
      )
    ]
  end

  def title("submissions.html", %{user: %User{} = _user} = _assigns) do
    "User submissions"
  end

  def title(_template, %{user: %User{} = _user} = _assigns) do
    "User"
  end
end
