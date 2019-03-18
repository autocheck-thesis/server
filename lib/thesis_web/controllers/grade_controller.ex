defmodule ThesisWeb.GradeController do
  use ThesisWeb, :controller
  require Logger

  plug :fetch_session

  def grade(conn, _params) do
    render(conn, "grade.html")
  end

  def grade_post(conn, %{"grade" => grade}) do
    url = get_session(conn, :lis_outcome_service_url)
    source_id = get_session(conn, :lis_result_sourcedid)

    case PlugLti.Grade.call(url, source_id, grade) do
      :ok ->
        text(conn, "Great success!")
      {:error, err} ->
        text(conn, "ERROR:\n #{err}")
    end
  end
end
