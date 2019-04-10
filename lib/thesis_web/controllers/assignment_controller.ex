defmodule ThesisWeb.AssignmentController do
  use ThesisWeb, :controller
  require Logger

  def index(conn, %{"assignment_id" => assignment_id}) do
    case Thesis.Repo.get(Thesis.Assignment, assignment_id) do
      nil ->
        raise "Assignment not found"

      assignment ->
        render(conn, "assignment.html",
          assignment: assignment,
          role: get_session(conn, :role)
        )
    end
  end

  def submit(conn, _params) do
  end
end
