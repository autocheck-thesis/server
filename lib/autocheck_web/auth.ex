defmodule AutocheckWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller

  def check_auth(conn, _args) do
    user = get_session(conn, :user)
    role = get_session(conn, :role)

    if user && role do
      conn
      |> assign(:user, user)
      |> assign(:role, role)
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(AutocheckWeb.ErrorView)
      |> render(:"403")
      |> halt()
    end
  end
end
