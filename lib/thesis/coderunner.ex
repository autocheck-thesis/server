defmodule Thesis.Coderunner do
  def run!(job, event_callback \\ &append_to_stream/2) do
    client = DockerAPI.connect()

    DockerAPI.Images.create(%{fromImage: job.image}, client)
    |> Enum.each(fn
      :end ->
        event_callback.(job, {:pull, :end})

      chunk ->
        event_callback.(job, parse_pull_chunk(chunk))
    end)

    container = %{
      Cmd: ["sh", "-c", job.cmd],
      Image: job.image,
      HostConfig: %{
        Binds: [
          "/var/run/docker.sock:/var/run/docker.sock"
        ]
      }
    }

    DockerAPI.Containers.run(job.id, container, client)

    DockerAPI.Containers.attach(job.id, client)
    |> Enum.each(fn
      :end ->
        event_callback.(job, {:run, :end})

      chunk ->
        event_callback.(job, {:run, chunk})
    end)

    DockerAPI.Containers.remove(job.id, true, client)
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
