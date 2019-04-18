defmodule ThesisWeb.AssignmentController do
  use ThesisWeb, :controller
  require Logger

  def index(conn, %{"assignment_id" => assignment_id}) do
    case Thesis.Repo.get(Thesis.Assignment, assignment_id) do
      nil ->
        raise "Assignment not found"

      assignment ->
        render(conn, "index.html",
          assignment: assignment,
          # changeset: Thesis.Assignment.changeset(assignment),
          role: get_session(conn, :role)
        )
    end
  end

  def submit(conn, %{"assignment_id" => assignment_id, "dsl" => dsl}) do
    case Thesis.Repo.get(Thesis.Assignment, assignment_id) do
      nil -> raise "Assignment not found"
      assignment -> assignment
    end
    |> Thesis.Assignment.changeset(%{dsl: dsl})
    |> Thesis.Repo.update()

    redirect(conn, to: Routes.assignment_path(conn, :index, assignment_id))
  end
end
