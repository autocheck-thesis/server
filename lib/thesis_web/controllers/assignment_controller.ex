defmodule ThesisWeb.AssignmentController do
  use ThesisWeb, :controller
  require Logger

  def index(conn, %{"assignment_id" => assignment_id, "assignment_name" => assignment_name}) do
    render(conn, "assignment.html",
      assignment_id: assignment_id,
      assignment_name: assignment_name,
      role: get_session(conn, :role)
    )
  end

  def submit(conn, %{
        "assignment_id" => assignment_id,
        "assignment_name" => assignment_name,
        "dsl" => dsl
      }) do

    %{cmd: cmd} = Thesis.DSL.parse_dsl(dsl)

    case Thesis.Repo.get_by(Thesis.Assignment, [assignment_id: assignment_id, name: assignment_name]) do
      nil -> %Thesis.Assignment{assignment_id: assignment_id, name: assignment_name, cmd: cmd, dsl: dsl}
      assignment -> assignment
    end
    |> Thesis.Assignment.changeset(%{dsl: dsl})
    |> Thesis.Repo.insert_or_update!()

    redirect(conn, to: Routes.assignment_path(conn, :index, assignment_id, assignment_name))
  end
end
