defmodule ThesisWeb.AssignmentController do
  use ThesisWeb, :controller
  require Logger

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Thesis.Repo.get!(Thesis.Assignment, assignment_id)

    render(conn, "index.html",
      assignment: assignment,
      role: role
    )
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
