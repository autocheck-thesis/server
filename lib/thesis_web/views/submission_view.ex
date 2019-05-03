defmodule ThesisWeb.SubmissionView do
  use ThesisWeb, :view

  def file_header_icon(:added), do: "plus square outline"
  def file_header_icon(:changed), do: "pencil alternate"
  def file_header_icon(:unchanged), do: "file outline"
  def file_header_icon(:removed), do: "minus square outline"

  def render("download.json", %{data: data}) do
    data
  end
end
