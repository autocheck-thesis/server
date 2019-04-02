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
      Thesis.JobWorker.QueueConsumer.start_link(job_id: job_id)
    end

    {:ok,
     assign(socket,
       log_lines: [],
       status: "Waiting to start"
     )}
  end

  # def handle_info(any, socket) do
  #   IO.inspect(any)
  #   {:noreply, socket}
  # end

  def handle_info(%Docker.AsyncReply{reply: {:chunk, %{"status" => status}}} = _reply, socket) do
    {:noreply, update(socket, :log_lines, &(&1 ++ ["#{status}\n"]))}
  end

  def handle_info(%Docker.AsyncReply{reply: {:chunk, [stdout: out]}} = _reply, socket) do
    {:noreply, update(socket, :log_lines, &(&1 ++ [out]))}
  end

  def handle_info(%Docker.AsyncReply{reply: {:chunk, [stderr: err]}} = _reply, socket) do
    {:noreply, update(socket, :log_lines, &(&1 ++ [err]))}
  end

  def handle_info(%Docker.AsyncReply{reply: {:chunk, chunks}} = _reply, socket) do
    for chunk <- Keyword.values(chunks) do
      {:noreply, update(socket, :log_lines, &(&1 ++ [chunk]))}
    end
  end

  def handle_info(%Docker.AsyncReply{reply: :done} = _reply, socket) do
    {:noreply, assign(socket, status: "Done")}
  end

  def handle_info({:error, _error} = _reply, socket) do
    {:noreply, assign(socket, status: "Something went wrong")}
  end
end
