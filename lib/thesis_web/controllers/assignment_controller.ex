defmodule ThesisWeb.AssignmentController do
  use ThesisWeb, :controller
  import Ecto.Query, only: [from: 2]
  require Logger

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Thesis.Repo.get!(Thesis.Assignment, assignment_id)

    configuration = Thesis.Repo.all(
      from(
        Thesis.Configuration,
        where: [assignment_id: ^assignment_id],
        order_by: :inserted_at,
        limit: 1
      )
    )
    |> case do
      [] -> nil
      [configuration] -> configuration
    end

    IO.puts("HEEEEEEEEEEEEEEEEEEEEEEEEEEJ")
    IO.inspect(configuration)
    IO.puts("HEEEEEEEEEEEEEEEEEEEEEEEEEEJ")

    render(conn, "index.html",
      assignment: assignment,
      configuration: configuration,
      role: role
    )
  end

  def submit(conn, %{"assignment_id" => assignment_id, "dsl" => dsl}) do
    Thesis.Configuration.changeset(%Thesis.Configuration{code: dsl})
    |> Thesis.Repo.insert!()

    redirect(conn, to: Routes.assignment_path(conn, :index, assignment_id))
  end
end
