defmodule Thesis.JobWorker do
  alias Thesis.Repo
  alias Thesis.Job

  require Logger

  def run(id) do
    job = Repo.get(Job, id)

    Logger.debug("Starting coderunner for job #{id}")

    {:ok, coderunner} = Thesis.Coderunner.start_link()
    Thesis.Coderunner.process(coderunner, job)

    job
    |> Ecto.Changeset.change(%{finished: true})
    |> Repo.update!()
  end
end
