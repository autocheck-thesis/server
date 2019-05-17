defmodule Thesis.Submissions.JobWorker do
  alias Thesis.Submissions
  alias Thesis.Coderunner

  require Logger

  @spec run(String.t()) :: any()
  def run(id) do
    job = Submissions.get_job!(id)

    Logger.debug("Starting coderunner for job #{id}")

    # {:ok, coderunner} = Thesis.Coderunner.start()
    # Thesis.Coderunner.process_job_local_image(coderunner, job)
    Coderunner.run!(job)

    Submissions.finish_job!(job)
  end
end
