defmodule ThesisWeb.JobView do
  use ThesisWeb, :view
  use Phoenix.HTML

  def render("index.html", _assigns),
    do: ~E"""
      <form method="post" enctype="multipart/form-data">
      <input type="file" name="file" id="file">
      <input type="submit" value="Upload" name="submit">
    </form>
    """
end
