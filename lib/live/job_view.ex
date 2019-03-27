defmodule ThesisWeb.JobLiveView do
  use Phoenix.LiveView
  import Thesis.Helpers
  # use GenStage

  def render(assigns) do
    ~L"""
      <div>Status: <%= @status %></div>
      <h2>Build log:</h2>
      <pre><code><%= for line <- @log_lines do %><span><%= line %></span><% end %></code></pre>
    """
  end

  def mount(%{user_id: _user_id, job_id: job_id} = _session, socket) do
    if connected?(socket) do
      Thesis.JobWorker.QueueConsumer.start_link([job_id: job_id])
    end

    {:ok,
     assign(socket,
       log_lines: [],
       status: "Waiting to start"
     )}
  end

  def handle_info({:reply, %Docker.AsyncReply{reply: {:chunk, [stdout: out]}}} = _reply, socket) do
    {:noreply, update(socket, :log_lines, &(&1 ++ [out]))}
  end

  def handle_info({:reply, %Docker.AsyncReply{reply: {:chunk, [stderr: err]}}} = _reply, socket) do
    {:noreply, update(socket, :log_lines, &(&1 ++ [err]))}
  end

  def handle_info({:reply, %Docker.AsyncReply{reply: :done}} = _reply, socket) do
    {:noreply, assign(socket, status: "Done")}
  end

  def handle_info({:error, _error} = _reply, socket) do
    {:noreply, assign(socket, status: "Something went wrong")}
  end
end
