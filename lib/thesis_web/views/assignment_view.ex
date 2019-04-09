defmodule ThesisWeb.AssignmentView do
  use ThesisWeb, :view

  def saved_dsl(assignment_id, assignment_name) do
    Thesis.Repo.get_by(Thesis.Assignment, [assignment_id: assignment_id, name: assignment_name]).dsl
  end
end
