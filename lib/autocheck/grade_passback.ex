defmodule Autocheck.GradePassback do
  alias Autocheck.Assignments
  alias Autocheck.Submissions
  alias Autocheck.Configuration

  def run(grade_passback_result_id) do
    %{job: %{submission_id: submission_id, result: result}} =
      Assignments.get_grade_passback_result!(grade_passback_result_id)

    %{author_id: user_id, assignment: assignment} = Submissions.get!(submission_id)

    %{code: code} = Assignments.get_latest_configuration!(assignment.id)
    %{grade: grade} = Configuration.parse_code(code)

    if grade do
      %{
        lis_result_sourcedid: lis_result_sourcedid,
        lis_outcome_service_url: lis_outcome_service_url
      } = Assignments.get_grade_passback!(assignment.id, user_id)

      score = if result_has_errors(result), do: 0, else: grade
      :ok = PlugLti.Grade.call(lis_outcome_service_url, lis_result_sourcedid, score)
    end
  end

  defp result_has_errors(result) do
    Enum.any?(result, &command_results_has_error(&1))
  end

  defp command_results_has_error(command_results) do
    Enum.any?(command_results, &match?(%{result: %{error: _error}}, &1))
  end
end
