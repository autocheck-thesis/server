defmodule ThesisWeb.IndexController do
  use ThesisWeb, :controller

  plug PlugLti

  def index(conn, _params) do
    conn |> text("Hello world")
  end
end
