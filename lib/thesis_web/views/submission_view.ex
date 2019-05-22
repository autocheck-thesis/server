defmodule ThesisWeb.SubmissionView do
  use ThesisWeb, :view

  alias Thesis.Configuration

  def main_sidebar_items(%Plug.Conn{assigns: %{role: :teacher}} = conn, assignment),
    do: [
      %{title: "Submit", href: Routes.submission_path(conn, :index, assignment.id)},
      %{
        title: "Previous submissions",
        href: Routes.submission_path(conn, :previous, assignment.id)
      },
      %{
        title: "Configure assignment",
        href: Routes.assignment_path(conn, :index, assignment.id)
      }
    ]

  def main_sidebar_items(conn, assignment),
    do: [
      %{title: "Submit", href: Routes.submission_path(conn, :index, assignment.id)},
      %{
        title: "Previous submissions",
        href: Routes.submission_path(conn, :previous, assignment.id)
      }
    ]

  def submission_sidebar_items(conn, submission),
    do: [
      %{title: "Submission", href: Routes.submission_path(conn, :show, submission.id)},
      %{title: "Source", href: Routes.submission_path(conn, :files, submission.id)},
      %{
        title: "Back to assignment",
        href: Routes.submission_path(conn, :submit, submission.assignment_id)
      }
    ]

  def file_header_icon(:added), do: "plus square outline"
  def file_header_icon(:changed), do: "pencil alternate"
  def file_header_icon(:unchanged), do: "file outline"
  def file_header_icon(:removed), do: "minus square outline"

  def render("download.json", %{data: data}) do
    data
  end

  def format_bytes(size) do
    "#{ceil(size / 1024)} kB"
  end
end
