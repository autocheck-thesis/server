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

    {_result, logs} = Enum.reduce(events, {nil, []}, &reduce_event/2)

    {:ok,
     assign(socket,
       submission: submission,
       log_lines: Enum.reverse(logs),
       role: role,
       job: job,
       results: job.result || []
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

    {result, logs} = Enum.reduce(events, {nil, []}, &reduce_event/2)

    socket =
      case result do
        nil -> socket
        _ -> assign(socket, :results, result)
      end

    socket = update(socket, :log_lines, &(&1 ++ Enum.reverse(logs)))

    {:noreply, socket}
  end

  def handle_event("rebuild", _, %Socket{assigns: %{submission: submission}} = socket) do
    job = Submissions.create_job!(submission)
    Thesis.Coderunner.start_event_stream(job)

    {:stop, redirect(socket, to: Routes.submission_path(socket, :show, submission.id))}
  end

  defp reduce_event(%EventStore.RecordedEvent{data: data}, {result, logs}) do
    case data do
      :init ->
        {result, [{:init, "Coderunner started job"} | logs]}

      {:pull, :end} ->
        {result, [{:done, "Image fetching done. Will now execute the job..."} | logs]}

      {:run, :end} ->
        {result, [{:done, "Process execution successful"} | logs]}

      {:pull, {_stream, text}} ->
        {result, [{:text, text} | logs]}

      {:run, {:stdio, text}} ->
        {result, [{:text, text |> String.replace(~r/\n$/, "")} | logs]}

      {:run, {:stderr, text}} ->
        {result, [{:supervisor, text |> String.replace(~r/\n$/, "")} | logs]}

      {:result, result} when is_binary(result) ->
        {Jason.decode!(result), logs}

      {:result, result} ->
        {result, logs}

      {:error, text} ->
        {result, [{:error, inspect(text)} | logs]}
    end
  end
end
