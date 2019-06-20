defmodule AutocheckWeb.AssignmentController do
  use AutocheckWeb, :controller
  require Logger

  alias Autocheck.Assignments

  def show(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Assignments.get_with_files!(assignment_id)

    configuration =
      try do
        Assignments.get_latest_configuration!(assignment_id)
      rescue
        _ -> Assignments.get_default_configuration()
      end

    render(conn, "show.html",
      assignment: assignment,
      configuration: configuration,
      role: role
    )
  end

  def submit(conn, %{
        "assignment_id" => assignment_id,
        "dsl" => code,
        "files" => uploaded_files
      }) do
    assignment = Assignments.get_with_files!(assignment_id)

    case Enum.reject(assignment.files, fn %{name: name} ->
           Enum.any?(uploaded_files, fn %{filename: filename} -> name != filename end)
         end) do
      [file] ->
        conn
        |> put_flash(:error, "File already exists: #{file.name}")
        |> redirect(to: Routes.assignment_path(conn, :show, assignment_id))

      [] ->
        files =
          for %Plug.Upload{filename: filename, path: path} <- uploaded_files,
              do: %{name: filename, contents: Elixir.File.read!(path)}

        Assignments.add_files(assignment_id, files)

        create_configuration(conn, code, assignment_id)
    end
  end

  def submit(conn, %{
        "assignment_id" => assignment_id,
        "dsl" => code
      }) do
    create_configuration(conn, code, assignment_id)
  end

  def create_configuration(conn, code, assignment_id) do
    Assignments.create_configuration!(%{code: code, assignment_id: assignment_id})

    redirect(conn, to: Routes.assignment_path(conn, :show, assignment_id))
  end

  def remove_file(%Plug.Conn{assigns: %{role: :teacher}} = conn, %{
        "assignment_id" => assignment_id,
        "name" => filename
      }) do
    Assignments.remove_file(assignment_id, filename)

    redirect(conn, to: Routes.assignment_path(conn, :show, assignment_id))
  end

  def remove_all_files(%Plug.Conn{assigns: %{role: :teacher}} = conn, %{
        "assignment_id" => assignment_id
      }) do
    Assignments.remove_all_files(assignment_id)

    redirect(conn, to: Routes.assignment_path(conn, :show, assignment_id))
  end

  def validate_configuration(%Plug.Conn{assigns: %{role: :teacher}} = conn, %{
        "configuration" => configuration
      }) do
    case Autocheck.Configuration.validate(configuration) do
      :ok ->
        json(conn, "OK")

      {:errors, errors} ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: errors})
    end
  end
end
