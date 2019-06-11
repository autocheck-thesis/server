defmodule Autocheck.Submissions.JobWorker do
  alias Autocheck.Submissions
  alias Autocheck.Coderunner

  require Logger

  @spec run(String.t()) :: any()
  def run(id) do
    job = Submissions.get_job!(id)

    Logger.debug("Starting coderunner for job #{id}")

    # {:ok, coderunner} = Autocheck.Coderunner.start()
    # Autocheck.Coderunner.process_job_local_image(coderunner, job)
    Coderunner.run!(job)
  end
end
