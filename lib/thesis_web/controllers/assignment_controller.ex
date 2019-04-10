defmodule ThesisWeb.AssignmentController do
  use ThesisWeb, :controller
  require Logger

  def index(conn, %{"assignment_id" => assignment_id}) do
    with assignment <- Thesis.Repo.get(Thesis.Assignment, assignment_id) do
      render(conn, "assignment.html",
        assignment: assignment,
        role: get_session(conn, :role)
      )
    else
      nil -> raise "Assignment not found"
      error -> raise error
    end
  end

  def submit(conn, _params) do
  end
end
