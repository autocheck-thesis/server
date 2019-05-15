defmodule Thesis.Submissions.JobWorker do
  alias Thesis.Submissions

  require Logger

  def run(id) do
    job = Submissions.get_job!(id)

    Logger.debug("Starting coderunner for job #{id}")

    {:ok, coderunner} = Thesis.Coderunner.start()
    Thesis.Coderunner.process_local_image(coderunner, job)

    Submissions.finish_job!(job)
  end
end
