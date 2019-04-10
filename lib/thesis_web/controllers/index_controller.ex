defmodule ThesisWeb.IndexController do
  use ThesisWeb, :controller

  require Logger

  plug PlugLti when action in [:launch]
  plug :fetch_session

  def launch(conn, params) do
    with %{
           "user_id" => lti_user_id,
           "roles" => roles,
           "ext_lti_assignment_id" => assignment_id,
           "resource_link_title" => assignment_name
         } <- params,
         {:ok, user} <- Thesis.Repo.get_or_insert(Thesis.User, %{lti_user_id: lti_user_id}),
         {:ok, assignment} <-
           Thesis.Repo.get_or_insert(Thesis.Assignment, %{
             id: assignment_id,
             name: assignment_name
           }) do
      role = determine_role(roles)

      conn
      |> put_session(:user, user)
      |> put_session(:role, role)
      |> redirect_user(role, assignment)
    else
      error -> raise error
    end
  end

  def index(conn, _params) do
    user = get_session(conn, :user)

    conn |> text("Welcome back user #{user.id} with lti_user_id #{user.lti_user_id}.")
  end

  defp redirect_user(conn, role, assignment) do
    case role do
      :student ->
        redirect(conn, to: Routes.submission_path(conn, :index, assignment.id))

      :teacher ->
        redirect(conn, to: Routes.assignment_path(conn, :index, assignment.id))
    end
  end

  defp determine_role(roles) do
    cond do
      roles =~ "Learner" ->
        :student

      roles =~ "Instructor" ->
        :teacher

      true ->
        :unknown
    end
  end
end
