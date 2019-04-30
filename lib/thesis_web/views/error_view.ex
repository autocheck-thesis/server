defmodule ThesisWeb.ErrorView do
  use ThesisWeb, :view

  def template_not_found(template, _assigns) do
    case Path.extname(template) do
      ".json" -> %{error: Phoenix.Controller.status_message_from_template(template)}
      _ -> Phoenix.Controller.status_message_from_template(template)
    end
  end
end
