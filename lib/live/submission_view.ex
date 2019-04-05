defmodule ThesisWeb.SubmissionLiveView do
  use Phoenix.LiveView
  alias Thesis.Coderunner.{Output, Error, Done}

  def render(assigns) do
    ~L"""
      <h2>Build log for submission <%= @submission.id %></h2>
      <pre id="log"><code><%= for line <- @log_lines do %><span><%= line %><br /></span><% end %></code></pre>
    """
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
    Enum.map(events, fn %EventStore.RecordedEvent{event_type: event_type, data: data} ->
      case data do
        %Output{text: text} ->
          String.trim(text)

        %Error{text: text} ->
          String.trim(text)

        %Done{} ->
          case event_type do
            "Coderunner.Pull" -> "--- Image fetching finished ---"
            "Coderunner.Follow" -> "--- Execution finished ---"
          end
      end
    end)
  end
end
