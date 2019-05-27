defmodule ThesisWeb.SubmissionLiveView do
  use Phoenix.LiveView

  alias Phoenix.LiveView.Socket
  alias Thesis.Submissions
  alias ThesisWeb.Router.Helpers, as: Routes

  def view_module(), do: ThesisWeb.SubmissionView

  def render(assigns) do
    ThesisWeb.SubmissionView.render("show.html", assigns)
  end

  def mount(
        %{submission: submission, job: job, events: events, role: role} = _session,
        socket
      ) do
    if connected?(socket) do
      EventStore.subscribe_to_stream(job.id, UUID.uuid4(), self(), start_from: length(events))
    end

    {:ok,
     assign(socket,
       submission: submission,
       log_lines: map_events(events),
       role: role,
       job: job
     )}
  end

  def mount(%{submission: submission, role: role} = _session, socket) do
    {:ok,
     assign(socket,
       submission: submission,
       log_lines: [{:error, "No job specified"}],
       role: role
     )}
  end

  def handle_info({:subscribed, subscription}, socket) do
    {:noreply, assign(socket, :subscription, subscription)}
  end

  def handle_info({:events, events}, socket) do
    EventStore.ack(socket.assigns.subscription, events)

    {:noreply, update(socket, :log_lines, &(&1 ++ map_events(events)))}
  end

  def handle_event("rebuild", _, %Socket{assigns: %{submission: submission}} = socket) do
    job = Submissions.create_job!(submission)
    Thesis.Coderunner.start_event_stream(job)

    {:stop, redirect(socket, to: Routes.submission_path(socket, :show, submission.id))}
  end

  defp map_events(events) do
    Enum.map(events, fn %EventStore.RecordedEvent{data: data} ->
      case data do
        :init ->
          {:init, "Coderunner started job"}

        {:pull, :end} ->
          {:done, "Image fetching done. Will now execute the job..."}

        {:run, :end} ->
          {:done, "Process execution successful"}

        {:pull, {_stream, text}} ->
          {:text, text}

        {:run, {:stdio, text}} ->
          {:text, text |> String.replace(~r/\n$/, "")}

        {:run, {:stderr, text}} ->
          {:supervisor, text |> String.replace(~r/\n$/, "")}

        {:error, text} ->
          {:error, inspect(text)}
      end
    end)
  end
end
