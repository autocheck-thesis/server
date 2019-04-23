defmodule ThesisWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller

  def check_auth(conn, _args) do
    user = get_session(conn, :user)
    role = get_session(conn, :role)

    if user && role do
      assign(conn, :user, user)
      assign(conn, :role, role)
    else
      conn
      |> put_flash(:danger, "You need to be signed in to access that page")
      |> redirect(to: ThesisWeb.Router.Helpers.index_path(conn, :index))
      |> halt()
    end
  end
end
