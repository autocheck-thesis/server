defmodule ThesisWeb.SubmissionLiveView do
  use Phoenix.LiveView
  alias Thesis.Coderunner.{Init, PullOutput, FollowOutput, PullDone, FollowDone, Error}

  def render(assigns) do
    ThesisWeb.SubmissionView.render("show.html", assigns)
  end

  def mount(
        %{user_id: _user_id, submission: submission, job: job, events: events} = _session,
        socket
      ) do
    if connected?(socket) do
      EventStore.subscribe_to_stream(job.id, UUID.uuid4(), self(), start_from: length(events))
    end

    {:ok,
     assign(socket,
       submission: submission,
       log_lines: map_events(events)
     )}
  end

  def handle_info({:subscribed, subscription}, socket) do
    {:noreply, assign(socket, :subscription, subscription)}
  end

  def handle_info({:events, events}, socket) do
    EventStore.ack(socket.assigns.subscription, events)

    {:noreply, update(socket, :log_lines, &(&1 ++ map_events(events)))}
  end

  defp map_events(events) do
    Enum.map(events, fn %EventStore.RecordedEvent{data: data, metadata: %{job_id: job_id}} ->
      case data do
        %Init{} ->
          {:init, "Coderunner started job #{job_id}"}

        %PullOutput{text: text} ->
          {:text, text}

        %FollowOutput{text: text} ->
          {:text, text}

        %PullDone{} ->
          {:done, "Image fetching done. Will now execute the job..."}

        %FollowDone{exit_code: code} ->
          {:done, "Process execution successful with exit code: #{code}"}

        %Error{text: text} ->
          {:error, text}
      end
    end)
  end
end
