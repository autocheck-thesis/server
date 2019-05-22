defmodule ThesisWeb.SharedView do
  use ThesisWeb, :view

  alias Thesis.Accounts.User
  alias Thesis.Submissions.Submission

  def user_link(conn, %User{} = user) do
    user_link(conn, user.id)
  end

  def user_link(conn, user_id) do
    href = ""

    ~E(<a href="<%= href %>" class="ui blue label"><i class="folder outline icon"></i><%= user_id %></a>)
  end

  def submission_link(conn, %Submission{} = submission) do
    submission_link(conn, submission.id)
  end

  def submission_link(conn, submission_id) do
    href = Routes.submission_path(conn, :show, submission_id)

    ~E(<a href="<%= href %>" class="ui orange label"><i class="user outline icon"></i><%= submission_id %></a>)
  end
end
