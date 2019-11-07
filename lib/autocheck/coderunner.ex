defmodule Autocheck.Coderunner do
  alias Autocheck.Submissions

  @image "autocheck-coderunner:latest"

  def run(job_id) do
    job = Submissions.get_job!(job_id)
    run!(job)
  end

  def run!(job) do
    try do
      client = DockerAPI.connect()

      unless DockerAPI.Images.exists(client, @image) do
        DockerAPI.Images.create(%{fromImage: @image}, client)
        |> Enum.each(fn
          :end ->
            append_to_stream(job, {:pull, :end})

          {:error, _} = error ->
            throw(error)

          chunk ->
            append_to_stream(job, parse_pull_chunk(chunk))
        end)
      end

      container = %{
        Cmd: generate_cmd(job),
        Image: @image,
        HostConfig: %{
          Binds: [
            "/var/run/docker.sock:/var/run/docker.sock",
            "/tmp/coderunner:/tmp/coderunner"
          ]
        }
      }

      DockerAPI.Containers.run(job.id, container, client)

      DockerAPI.Containers.logs(job.id, client)
      |> Enum.each(fn
        :end ->
          append_to_stream(job, {:run, :end})

        {:error, _} = error ->
          throw(error)

        chunk ->
          append_to_stream(job, {:run, chunk})
      end)

      Task.start(DockerAPI.Containers, :remove, [job.id, true, client])
    rescue
      error in HTTPoison.Error ->
        append_to_stream(job, {:error, "Docker connection error"})
        raise(error)

      error ->
        append_to_stream(job, {:error, "Unknown error"})
        raise(error)
    catch
      error ->
        append_to_stream(job, {:error, "Unknown error"})
        raise(error)
    end
  end

  defp generate_cmd(job) do
    download_url =
      Application.get_env(:autocheck, :submission_download_hostname) <>
        AutocheckWeb.Router.Helpers.submission_path(
          AutocheckWeb.Endpoint,
          :download,
          job.download_token
        )

    callback_url =
      Application.get_env(:autocheck, :submission_download_hostname) <>
        AutocheckWeb.Router.Helpers.submission_path(
          AutocheckWeb.Endpoint,
          :download_callback,
          job.download_token
        )

    ["remote", download_url, callback_url]
  end

  defp parse_pull_chunk(chunk) do
    case chunk do
      %{"status" => text, "progress" => progress} -> {:pull, "#{text}: #{progress}"}
      %{"status" => text} -> {:pull, text}
      %{"message" => text} -> {:error, text}
    end
  end

  def start_event_stream(job) do
    append_to_stream(job, :init)
  end

  def append_to_stream(job, event) when not is_list(event) do
    append_to_stream(job, [event])
  end

  def append_to_stream(job, events) do
    events =
      for event <- events, do: %EventStore.EventData{event_type: event_type(event), data: event}

    EventStore.append_to_stream(job.id, :any_version, events)
  end

  defp event_type(event) when is_atom(event), do: Atom.to_string(event)
  defp event_type({event, _}), do: Atom.to_string(event)
end
