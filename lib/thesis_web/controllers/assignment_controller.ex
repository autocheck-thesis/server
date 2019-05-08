defmodule ThesisWeb.AssignmentController do
  use ThesisWeb, :controller
  import Ecto.Query, only: [from: 2]
  require Logger

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Thesis.Repo.get!(Thesis.Assignment, assignment_id)

    configuration = Thesis.Repo.one(
      from(
        Thesis.Configuration,
        where: [assignment_id: ^assignment_id],
        order_by: [desc: :inserted_at],
        limit: 1
      )
    )

    render(conn, "index.html",
      assignment: assignment,
      configuration: configuration,
      role: role
    )
  end

  def submit(conn, %{"assignment_id" => assignment_id, "dsl" => dsl}) do
    Thesis.Configuration.changeset(%Thesis.Configuration{code: dsl, assignment_id: assignment_id})
    |> Thesis.Repo.insert!()

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
