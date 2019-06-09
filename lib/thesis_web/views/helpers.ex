defmodule ThesisWeb.Views.Helpers.Link do
  defstruct [:title, :href, :icon]
end

defmodule ThesisWeb.Views.Helpers.LinkSeparator do
  defstruct [:title, :icon]
end

defmodule ThesisWeb.Views.Helpers do
  alias ThesisWeb.Views.Helpers.{Link, LinkSeparator}

  def icon(:assignment), do: "tasks icon"
  def icon(:user), do: "user icon"
  def icon(:submission), do: "box icon"
  def icon(:submissions), do: "boxes icon"
  def icon(:terminal), do: "terminal icon"
  def icon(:comment), do: "comment icon"
  def icon(:file), do: "file icon"
  def icon(:files), do: "copy icon"
  def icon(:configure), do: "cog icon"
  def icon(:upload_submission), do: "upload icon"
  def icon(:file_added), do: "plus square outline icon"
  def icon(:file_changed), do: "pencil alternate icon"
  def icon(:file_unchanged), do: "file outline icon"
  def icon(:file_removed), do: "minus square outline icon"
  def icon(:warning), do: "warning sign icon"
  def icon(:check), do: "check icon"
  def icon(:step), do: "clipboard outline icon"
  def icon(:command), do: "file outline icon"
  def icon(_), do: icon()
  def icon(), do: "icon"

  def menu_link(title, href, icon_atom \\ nil) do
    %Link{title: title, href: href, icon: icon(icon_atom)}
  end

  def menu_title(title, icon_atom \\ nil) do
    %LinkSeparator{title: title, icon: icon(icon_atom)}
  end
end
