defmodule ThesisWeb.AssignmentController do
  use ThesisWeb, :controller
  require Logger

  alias Thesis.Assignments

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Assignments.get!(assignment_id)

    configuration =
      case Assignments.get_latest_configuration!(assignment_id) do
        nil -> Assignments.get_default_configuration()
        configuration -> configuration
      end

    render(conn, "index.html",
      assignment: assignment,
      configuration: configuration,
      role: role
    )
  end

  def submit(conn, %{"assignment_id" => assignment_id, "dsl" => dsl}) do
    Assignments.create_configuration!(%{code: dsl, assignment_id: assignment_id})

    redirect(conn, to: Routes.assignment_path(conn, :index, assignment_id))
  end

  def validate_configuration(%Plug.Conn{assigns: %{role: :teacher}} = conn, %{
        "configuration" => configuration
      }) do
    case Thesis.DSL.Parser.parse_dsl(configuration) do
      {:error, error} -> conn |> put_status(:bad_request) |> json(%{error: error})
      _ -> json(conn, "OK")
    end
  end
end
