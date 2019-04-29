defmodule ThesisWeb.SubmissionView do
  use ThesisWeb, :view

  def render("download.json", %{data: data}) do
    data
  end
end
