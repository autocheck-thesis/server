defmodule AutocheckWeb.SubmissionView do
  use AutocheckWeb, :view

  alias Autocheck.Submissions.Submission

  def main_sidebar_items(%Plug.Conn{assigns: %{role: :teacher}} = conn, assignment) do
    [
      menu_link(
        "Upload",
        Routes.submission_path(conn, :index, assignment.id),
        :upload_submission
      ),
      menu_link(
        "Previous submissions",
        Routes.submission_path(conn, :previous, assignment.id),
        :submissions
      ),
      menu_title("Administration"),
      menu_link(
        "Assignment setup",
        Routes.assignment_path(conn, :show, assignment.id),
        :configure
      )
    ]
  end

  def main_sidebar_items(conn, assignment) do
    [
      menu_link(
        "Upload",
        Routes.submission_path(conn, :index, assignment.id),
        :upload_submission
      ),
      menu_link(
        "Previous submissions",
        Routes.submission_path(conn, :previous, assignment.id),
        :submissions
      )
    ]
  end

  def submission_sidebar_items(conn, submission) do
    [
      menu_link(
        "Submission",
        Routes.submission_path(conn, :show, submission.id),
        :submission
      ),
      menu_link(
        "Source",
        Routes.submission_path(conn, :files, submission.id),
        :files
      ),
      menu_title("Links"),
      menu_link(
        "Go to assignment",
        Routes.submission_path(conn, :submit, submission.assignment_id),
        :assignment
      )
    ]
  end

  def title("files.html", %{submission: %Submission{} = _user} = _assigns) do
    "Source"
  end

  def title("index.html", _assigns) do
    "Upload submission"
  end

  def title("previous.html", _assigns) do
    "Previous submissions"
  end

  def title(_template, _assigns) do
    "Submission"
  end

  def file_header_icon(:added), do: icon(:file_added)
  def file_header_icon(:changed), do: icon(:file_changed)
  def file_header_icon(:unchanged), do: icon(:file_unchanged)
  def file_header_icon(:removed), do: icon(:file_removed)

  def render("download.json", %{data: data}) do
    data
  end

  def render("download_callback.json", %{job: job}) do
    job.id
  end

  def command_results_has_error(command_results) do
    Enum.any?(command_results, &match?(%{"result" => %{"error" => _error}}, &1))
  end
end
