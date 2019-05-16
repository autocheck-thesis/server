defmodule ThesisWeb.AssignmentController do
  use ThesisWeb, :controller
  require Logger

  alias Thesis.Assignments

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Assignments.get!(assignment_id)

    configuration =
      try do
        Assignments.get_latest_configuration!(assignment_id)
      rescue
        _ -> Assignments.get_default_configuration()
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
    case Thesis.Configuration.validate(configuration) do
      :ok ->
        json(conn, "OK")

      {:errors, errors} ->
        IO.inspect(errors)
        conn
        |> put_status(:bad_request)
        |> json(%{errors: errors})
    end
  end
end
