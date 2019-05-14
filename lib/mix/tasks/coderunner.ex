defmodule Mix.Tasks.Coderunner do
  use Mix.Task

  alias Thesis.Submissions.Job
  alias Thesis.Coderunner
  alias Thesis.Coderunner.{Init, PullOutput, FollowOutput, PullDone, FollowDone, Error}

  alias Thesis.Configuration

  @shortdoc "Test job locally"
  def run(args) do
    Logger.configure(level: :error)
    run_job(args)
  end

  defp run_job([]) do
    IO.puts(:stderr, "A configuration file is required")
  end

  defp run_job([configuration_filename]) do
    {:ok, _started} = Application.ensure_all_started(:hackney)

    configuration =
      configuration_filename
      |> File.read!()
      |> Configuration.get_testing_fields()

    IO.inspect(configuration)

    {:ok, coderunner} = Coderunner.start(event_callback: &log_event/2)

    # %{image: image} = configuration

    download_url = ""

    job = %Job{
      image: "jcmmagnusson/coderunner-supervisor:0.1",
      cmd: """
      cd coderunner-supervisor
      mix local.hex --force
      mix test_suite '#{download_url}'
      """
    }

    Coderunner.process(coderunner, job)

    ref = Process.monitor(coderunner)

    receive do
      {:DOWN, ^ref, :process, ^coderunner, :normal} ->
        IO.puts("Job done.")

      {:DOWN, ^ref, :process, ^coderunner, _msg} ->
        IO.puts("Received :DOWN from #{inspect(coderunner)}")
    end
  end

  def log_event(%Job{id: job_id} = _job, event) do
    case event do
      %Init{} ->
        IO.puts("Coderunner started job #{job_id}")

      %PullOutput{text: text} ->
        IO.puts(text)

      %FollowOutput{text: text} ->
        IO.puts(text)

      %PullDone{} ->
        IO.puts("Image fetching done. Will now execute the job...")

      %FollowDone{exit_code: code} ->
        IO.puts("Process execution successful with exit code: #{code}")

      %Error{text: text} ->
        IO.puts(:stderr, text)
    end
  end
end
