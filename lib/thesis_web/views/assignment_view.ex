defmodule ThesisWeb.AssignmentView do
  use ThesisWeb, :view

  alias Thesis.Assignments.Assignment

  def assignment_sidebar_items(%Plug.Conn{} = conn, %Assignment{} = assignment) do
    [
      menu_link(
        "Setup",
        Routes.assignment_path(conn, :show, assignment.id),
        :configure
      ),
      menu_title("Links"),
      menu_link(
        "Go to submission",
        Routes.submission_path(conn, :index, assignment.id),
        :upload_submission
      )
    ]
  end

  def title("show.html", _assigns) do
    "Assignment setup"
  end

  def title(_, _assigns) do
    "Assignment"
  end
end
