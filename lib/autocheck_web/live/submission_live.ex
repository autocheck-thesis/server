defmodule AutocheckWeb.SubmissionLive do
  use Phoenix.LiveView

  alias Phoenix.LiveView.Socket
  alias Autocheck.Submissions
  alias AutocheckWeb.Router.Helpers, as: Routes

  def view_module(), do: AutocheckWeb.SubmissionView

  def render(assigns) do
    AutocheckWeb.SubmissionView.render("show.html", assigns)
  end

  def mount(
        _params,
        %{"submission" => submission, "job" => job, "events" => events, "role" => role} =
          _session,
        socket
      ) do
    if connected?(socket) do
      EventStore.subscribe_to_stream(job.id, UUID.uuid4(), self(), start_from: length(events))
    end

    {_result, logs} = Enum.reduce(events, {nil, []}, &reduce_event/2)

    {:ok,
     socket
     |> assign(
       submission: submission,
       role: role,
       job: job,
       results: job.result || [],
       page_title: "Autocheck - Submission details"
     ), temporary_assigns: [log_lines: Enum.reverse(logs)]}
  end

  def mount(_params, %{"submission" => submission, "role" => role} = _session, socket) do
    {:ok,
     assign(socket,
       submission: submission,
       role: role,
       log_lines: [{:error, "No job specified"}],
       page_title: "Autocheck - Submission details"
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

    {:noreply, assign(socket, :log_lines, Enum.reverse(logs))}
  end

  def handle_event("rebuild", _, %Socket{assigns: %{submission: submission}} = socket) do
    job = Submissions.create_job!(submission)
    Autocheck.Coderunner.start_event_stream(job)

    {:noreply, redirect(socket, to: Routes.submission_path(socket, :show, submission.id))}
  end

  defp reduce_event(
         %EventStore.RecordedEvent{data: data, event_number: event_number},
         {result, logs}
       ) do
    case data do
      :init ->
        {result, [{event_number, :init, "Coderunner started job"} | logs]}

      {:pull, :end} ->
        {result,
         [{event_number, :done, "Image fetching done. Will now execute the job..."} | logs]}

      {:run, :end} ->
        {result, [{event_number, :done, "Process execution successful"} | logs]}

      {:pull, text} ->
        {result, [{event_number, :text, text} | logs]}

      {:run, {:stdio, text}} ->
        {result, [{event_number, :text, text |> String.replace(~r/\n$/, "")} | logs]}

      {:run, {:stderr, text}} ->
        {result, [{event_number, :supervisor, text |> String.replace(~r/\n$/, "")} | logs]}

      {:result, result} when is_binary(result) ->
        {Jason.decode!(result), logs}

      {:result, result} ->
        {result, logs}

      {:error, text} when is_binary(text) ->
        {result, [{event_number, :error, text} | logs]}

      {:error, text} ->
        {result, [{event_number, :error, inspect(text)} | logs]}
    end
  end
end
