defmodule AutocheckWeb.LayoutView do
  use AutocheckWeb, :view

  def title(conn, assigns) do
    if Map.has_key?(assigns, :live_view_module) do
      module = assigns[:live_view_module]
      "Autocheck - #{module.title(:live, assigns)}"
    else
      "Autocheck"
    end
  end
end
