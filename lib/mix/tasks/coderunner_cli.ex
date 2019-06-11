defmodule Mix.Tasks.Coderunner do
  use Mix.Task

  alias Autocheck.Submissions.Job
  alias Autocheck.Configuration

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
      |> Configuration.parse_code()
      |> Map.from_struct()

    # IO.inspect(configuration)

    %{image: _image} = configuration

    job = %Job{
      id: Ecto.UUID.autogenerate(),
      download_token: ""
    }

    Autocheck.Coderunner.run!(job, &log_event/2)
  end

  def log_event(%Job{} = _job, event) do
    case event do
      :init ->
        IO.puts("Coderunner started job")

      {:pull, :end} ->
        IO.puts("Image fetching done. Will now execute the job...")

      {:run, :end} ->
        IO.puts("Process execution successful")

      {:pull, {stream, text}} ->
        IO.puts(stream, text)

      {:run, {:stdio, text}} ->
        IO.write(text)

      {:run, {:stderr, text}} ->
        IO.write("\e[34m" <> text <> "\e[39m")

      {:error, text} ->
        IO.puts(:stderr, text)

      {:stream, stream} ->
        IO.puts("Now in stream #{stream}")

      _ ->
        IO.puts(event)
    end
  end
end
