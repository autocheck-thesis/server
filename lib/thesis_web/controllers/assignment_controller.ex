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
    assignment =
      Thesis.Repo.get!(Thesis.Assignment, assignment_id)
      |> Thesis.Assignment.changeset(%{dsl: dsl})
      |> Thesis.Repo.update!()
      |> Thesis.Repo.preload(:configuration)

    Thesis.DSL.Parser.parse_dsl(dsl)
    |> Thesis.DSL.Parser.persist(assignment)

    redirect(conn, to: Routes.assignment_path(conn, :index, assignment_id))
  end

  def validate_configuration(%Plug.Conn{assigns: %{role: :teacher}} = conn, %{
        "configuration" => configuration
      }) do
    case Thesis.DSL.Parser.parse_dsl(configuration) do
      {:error, error} -> conn |> put_status(:bad_request) |> text(error)
      _ -> text(conn, "OK")
    end
  end
end
