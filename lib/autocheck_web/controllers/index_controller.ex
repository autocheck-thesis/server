defmodule AutocheckWeb.IndexController do
  use AutocheckWeb, :controller
  alias Autocheck.Accounts
  alias Autocheck.Assignments

  require Logger

  plug PlugLti when action in [:launch]

  def launch(
        conn,
        %{
          "user_id" => lti_user_id,
          "roles" => roles,
          "ext_lti_assignment_id" => assignment_id,
          "resource_link_title" => assignment_name
        } = params
      ) do
    user = Accounts.get_or_insert!(%{lti_user_id: lti_user_id})
    assignment = Assignments.get_or_insert!(%{id: assignment_id, name: assignment_name})

    with {:ok, lis_outcome_service_url} <- Map.fetch(params, "lis_outcome_service_url"),
         {:ok, lis_result_sourcedid} <- Map.fetch(params, "lis_result_sourcedid") do
      Assignments.set_grade_passback!(
        assignment,
        user,
        lis_outcome_service_url,
        lis_result_sourcedid
      )

      Logger.info("Added grade passback")
    end

    role = Accounts.determine_role(roles)

    conn
    |> put_session(:user, user)
    |> put_session(:role, role)
    |> redirect_user(role, assignment)
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end

  defp redirect_user(conn, role, assignment) do
    case role do
      :student ->
        redirect(conn, to: Routes.submission_path(conn, :index, assignment.id))

      :teacher ->
        redirect(conn, to: Routes.assignment_path(conn, :show, assignment.id))
    end
  end
end
